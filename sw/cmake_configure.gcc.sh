#!/bin/bash

set -eu

# To invoke this script anywhere, change to its directory first before getting git dir.
PULP_GIT_DIRECTORY="$(cd "$(readlink -f "$(dirname "$0")")" && git rev-parse --show-toplevel)"


#####################
# Collect processes #
#####################

# Processes
PROCS=()

function collect_procs {
    local proc_dir="$1"
    # Read null terminated directory, to overcome spaces in path.
    # Reference: https://stackoverflow.com/a/8677566/2419510
    while IFS= read -r -d $'\0' entry; do
        PROCS+=( "$(basename "$entry")" )
    done < <(find "$proc_dir" -mindepth 1 -maxdepth 1 -type d -print0)
}

collect_procs "$PULP_GIT_DIRECTORY/process"
if [ -d "${ICB_PATH-}" ]; then
    collect_procs "${ICB_PATH}/process"
fi

# Sort processes by name
# Reference: https://stackoverflow.com/a/7442583/2419510
readarray -t SORTED_PROCS < <(printf '%s\0' "${PROCS[@]}" | sort -z | xargs -0n1)


# Join elements in an array
# Reference: https://stackoverflow.com/a/17841619/2419510
function join_by { local d=${1-} f=${2-}; if shift 2; then printf %s "$f" "${@/#/$d}"; fi; }

ICB_PROCS_STR="$(join_by ', ' "${SORTED_PROCS[@]}")"


#################
# Parse options #
#################
OPTS=$(getopt -o he:r:cm:p: \
              -l help,process:,core:,coverage,memload:,postlayout: \
              -n "$(basename $0)" \
              -- "$@")

if [ $? != 0 ] ; then exit 2 ; fi

eval set -- "$OPTS"

DEFAULT_PROCESS="functional"
DEFAULT_CORE="zeroriscy"
DEFAULT_COVERAGE=0
DEFAULT_MEMLOAD="PRELOAD"
DEFAULT_POSTLAYOUT=""

HELP=
PROCESS="$DEFAULT_PROCESS"
CORE="$DEFAULT_CORE"
COVERAGE="$DEFAULT_COVERAGE"
MEMLOAD="$DEFAULT_MEMLOAD"
POSTLAYOUT="$DEFAULT_POSTLAYOUT"

while true; do
    case "${1-}" in
        -h | --help)        HELP=true; shift;;
        -e | --process)     PROCESS="$2"; shift 2;;
        -r | --core)        CORE="$2"; shift 2;;
        -c | --coverage)    COVERAGE=1; shift;;
        -m | --memload)     MEMLOAD="$2"; shift 2;;
        -p | --postlayout)  POSTLAYOUT="$2"; shift 2;;
        -- ) shift;;
        * )  if [ -z "${1-}" ]; then break; else echo "Unexpected positional argument: $1" >&2; exit 2; fi
    esac
done

function show_help {
    echo "Usage: $(basename "$0") OPTIONS"
    echo
    echo "Generate Pulpino Makefile"
    echo
    echo "Options:"
    echo
    echo "-e, --process     process. Valid values: ${ICB_PROCS_STR} (default: $DEFAULT_PROCESS)"
    echo "-r, --core        core. Valid cores: zeroriscy, ri5cy, ri5cyfpu (default: $DEFAULT_CORE)"
    echo "-c, --coverage    Enable RTL coverage (default: $DEFAULT_COVERAGE)"
    echo "-m, --memload     ctest memload methods. Valid values: PRELOAD, SPI, STANDALONE (default: $DEFAULT_MEMLOAD)"
    echo "-p, --postlayout  ctest postlayout category. Valid values: FUNC, TT, SS, FF (default: $DEFAULT_POSTLAYOUT)"
    echo "-h, --help        display this help"
}

if [ "$HELP" = true ]; then
    show_help
    exit 0
fi

# PROCESS must be valid
if [[ ! " ${SORTED_PROCS[@]} " =~ " ${PROCESS} " ]]; then
    echo "Unknown process value: $PROCESS. It must be one of ${ICB_PROCS_STR}" >/dev/stderr
    exit 2
fi

# CORE must not be empty
case "$CORE" in 
    zeroriscy|ri5cy|ri5cyfpu)
    ;;
    *)
    echo "Unknown core: $CORE. It must be one of 'zeroriscy', 'ri5cy', 'ri5cyfpu'" >/dev/stderr
    exit 2
    ;;
esac


# Valid MEMLOAD values are 'SPI', 'STANDALONE', 'PRELOAD'
case "$MEMLOAD" in
    PRELOAD|SPI|STANDALONE)
    ;;
    *)
    echo "Unknown memload value: $MEMLOAD. It must be one of 'PRELOAD', 'SPI', 'STANDALONE'" >/dev/stderr
    exit 2
    ;;
esac

# Valid POSTLAYOUT values are '', 'FUNC', 'TT', 'SS', 'FF'
case "$POSTLAYOUT" in
    ''|FUNC|TT|SS|FF)
    ;;
    *)
    echo "Unknown postlayout value: $POSTLAYOUT. It must be one of 'FUNC', 'TT', 'SS', 'FF'" >/dev/stderr
    exit 2
    ;;
esac

# Currently, only MEMLOAD=SPI/STANDALONE can be combined with non-empty postlayout.
if [ -n "$POSTLAYOUT" ]; then
    # if [ "$MEMLOAD" = "SPI" ]; then
    #     # Reference: https://stackoverflow.com/a/17583599/2419510
    #     :
    # else
    #   echo 'Only combination "--memload SPI --postlayout" is supported' >/dev/stderr
    #   exit 2
    # fi
    case "$MEMLOAD" in
        SPI|STANDALONE)
        ;;
        *)
        echo "Only '--memload SPI' or '--memload STANDALONE' is supported, when '--postlayout <category>' is specified" >/dev/stderr
        exit 2
        ;;
    esac
fi


OBJDUMP=`which riscv32-unknown-elf-objdump`
OBJCOPY=`which riscv32-unknown-elf-objcopy`

COMPILER=`which riscv32-unknown-elf-gcc`
RANLIB=`which riscv32-unknown-elf-ranlib`

VSIM=`which vsim`
VCOVER=`which vcover`

TARGET_C_FLAGS="-O3 -m32 -g"
#TARGET_C_FLAGS="-O2 -g -falign-functions=16  -funroll-all-loops"

# if you want to have compressed instructions, set this to 1
RVC=0

case "$CORE" in
    zeroriscy)
    # if you are using zero-riscy, set this to 1, otherwise it uses RISCY
    USE_ZERO_RISCY=1
    
    # set this to 1 if you are using the Floating Point extensions for riscy only
    RISCY_RV32F=0
    
    # zeroriscy with the multiplier
    ZERO_RV32M=1
    # zeroriscy with only 16 registers
    ZERO_RV32E=0
    
    # riscy with PULPextensions, it is assumed you use the ETH GCC Compiler
    GCC_MARCH="RV32IM"
    ;;

    ri5cy)
    # if you are using zero-riscy, set this to 1, otherwise it uses RISCY
    USE_ZERO_RISCY=0
    
    # set this to 1 if you are using the Floating Point extensions for riscy only
    RISCY_RV32F=0
    
    # zeroriscy with the multiplier
    ZERO_RV32M=0
    # zeroriscy with only 16 registers
    ZERO_RV32E=0
    
    # riscy with PULPextensions, it is assumed you use the ETH GCC Compiler
    GCC_MARCH="IMXpulpv2"
    ;;

    ri5cyfpu)
    # if you are using zero-riscy, set this to 1, otherwise it uses RISCY
    USE_ZERO_RISCY=0
    
    # set this to 1 if you are using the Floating Point extensions for riscy only
    RISCY_RV32F=1
    
    # zeroriscy with the multiplier
    ZERO_RV32M=0
    # zeroriscy with only 16 registers
    ZERO_RV32E=0
    
    # riscy with PULPextensions, it is assumed you use the ETH GCC Compiler
    GCC_MARCH="IMFDXpulpv2"
    # dct case report illegal instruction on:
    #     5bc:       d20a8053                fcvt.d.w        ft0,s5 
    # 
    # By checking ips/riscv/riscv_tracer.sv, only these fcvt instuctions are supported:
    # fcvt.w.s
    # fcvt.wu.s
    # fcvt.s.w
    # fcvt.s.wu
    # 
    # By checking ri5cy_gnu_toolchain/build/src/binutils/opcodes/riscv-opc.c
    # The above instructions are single-precision floating point instructions.
    # 
    # fcvt.d.w is a double-precision floating-point instruction.
    # And I guess ri5cyfpu does not support double-precision.
    # 
    # By reading ips/fpu/document/Datasheet_of_FMAC.pdf, the fpu only supports single-precision.
    # 
    # But I cannot use "-march=IMFXpulpv2" to get rid of double:
    # > cc1: error: -march=IMFXpulpv2: single-precision-only is not yet supported
    # 
    # This issue has been discussed here:
    # https://github.com/pulp-platform/ri5cy_gnu_toolchain/issues/9
    # I must use "-march=IMFDXpulpv2", and combine this option with another '-mfpdouble=float'.
    # 
    # 
    # '-mfpdouble=float' gcc crash on dct case.
    # '-mfpdouble=float -fsingle-precision-constant' gcc crash on dct case.
    # '-fsingle-precision-constant -mfpdouble=float' gcc crash on dct case.
    # '-fsingle-precision-constant' NO gcc crash on dct case.
    #
    # Finally I gave up on double support.
    # I think it is best to let code contains no double at all.
    ;;

    *)
        echo "Never be here" >/dev/stderr
        exit 1
    ;;
esac

#compile arduino lib
ARDUINO_LIB=1

SIM_DIRECTORY="$PULP_GIT_DIRECTORY/vsim"

# Construct ARG_TB according to MEMLOAD and postlayout
case "$POSTLAYOUT" in
    '')
        ARG_TB=run.tcl
        PL_CORNER=''
    ;;
    FUNC|TT|SS|FF)
        ARG_TB=run_pl.tcl
        PL_CORNER="$POSTLAYOUT"
    ;;
    *)
        echo "Never be here" >/dev/stderr
        exit 1
    ;;
esac


cmake "$PULP_GIT_DIRECTORY"/sw/ \
    -DPULP_MODELSIM_DIRECTORY="$SIM_DIRECTORY" \
    -DCMAKE_C_COMPILER="$COMPILER" \
    -DVSIM="$VSIM" \
    -DVCOVER="$VCOVER" \
    -DRTL_COVERAGE="$COVERAGE" \
    -DRVC="$RVC" \
    -DRISCY_RV32F="$RISCY_RV32F" \
    -DUSE_ZERO_RISCY="$USE_ZERO_RISCY" \
    -DZERO_RV32M="$ZERO_RV32M" \
    -DZERO_RV32E="$ZERO_RV32E" \
    -DGCC_MARCH="$GCC_MARCH" \
    -DMEMLOAD="$MEMLOAD" \
    -DARDUINO_LIB="$ARDUINO_LIB" \
    -DPL_CORNER="$PL_CORNER" \
    -DCMAKE_C_FLAGS="$TARGET_C_FLAGS" \
    -DCMAKE_OBJCOPY="$OBJCOPY" \
    -DCMAKE_OBJDUMP="$OBJDUMP" \
    -DARG_TB="$ARG_TB" \
    -DPROCESS="$PROCESS" \
    -DICB_PATH="${ICB_PATH:-}" \
    -DPULPINO_V_PATH="${PULPINO_V_PATH:-}"

# Add -G "Ninja" to the cmake call above to use ninja instead of make
