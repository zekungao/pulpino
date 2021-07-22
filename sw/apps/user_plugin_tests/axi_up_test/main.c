#include <stdio.h>
#include "int.h"
#include "event.h"
#include "user_plugin/axi.h"

#define IRQ_UP_IDX 22

#define mb() __asm__ __volatile__ ("" : : : "memory")

// Reference: https://stackoverflow.com/a/3437484/2419510
#define max(a,b) \
    ({ __typeof__ (a) _a = (a); \
       __typeof__ (b) _b = (b); \
       _a > _b ? _a : _b; })

#define min(a,b) \
    ({ __typeof__ (a) _a = (a); \
       __typeof__ (b) _b = (b); \
       _a < _b ? _a : _b; })

// Must use volatile,
// because it is used to communicate between IRQ and main thread.
volatile int g_up_int_triggers = 0;

void ISR_UP() {
    // Clear interrupt within user plugin peripheral
    UP_AXI_CMD = UP_AXI_CMD_CLR_INT_BIT;
    ICP = 1 << IRQ_UP_IDX;

    ++g_up_int_triggers;
    printf("In User Plugin interrupt\n");
}

void print_array(int* array, size_t word_n) {
    const size_t head_max_n = 3;
    const size_t tail_max_n = 3;

    size_t head_n = min(head_max_n, word_n);

    for (size_t i = 0; i < head_n; ++i) {
        printf(" %d", array[i]);
    }

    if (word_n > head_n) {
        size_t tail_start = max(head_max_n, word_n - tail_max_n);
        if (tail_start != head_max_n) {
            printf(" ...");
        }

        for (size_t i = tail_start; i < word_n; ++i) {
            printf(" %d", array[i]);
        }
    }
}

void do_check_ctrl_src_dst_size(int* errors, int expected_ctrl, int expected_src, int expected_dst, int expected_size) {
    int ctrl_v = UP_AXI_CTRL;
    int src_v = UP_AXI_SRC_ADDR;
    int dst_v = UP_AXI_DST_ADDR;
    int size_v = UP_AXI_SIZE;

    if (ctrl_v != expected_ctrl) {
        ++(*errors);
        printf("Error: ctrl: 0x%X, expected ctrl: 0x%X\n", ctrl_v, expected_ctrl);
    }
    if (src_v != expected_src) {
        ++(*errors);
        printf("Error: src: 0x%X, expected src: 0x%X\n", src_v, expected_src);
    }
    if (dst_v != expected_dst) {
        ++(*errors);
        printf("Error: dst: 0x%X, expected dst: 0x%X\n", dst_v, expected_dst);
    }
    if (size_v != expected_size) {
        ++(*errors);
        printf("Error: size: 0x%X, expected size: 0x%X\n", size_v, expected_size);
    }
}

void do_compare(int* errors, int* src, int* dst, size_t word_n) {
    for (size_t i = 0; i < word_n; ++i) {
        int src_v = src[i];
        int dst_v = dst[i];
        int expected_v = src_v * 2;
        if (expected_v != dst_v) {
            ++(*errors);
            printf("Error: src[%d]: %d, dst[%d]: %d, expected dst[%d]: %d\n",
                   i, src_v, i, dst_v, i, expected_v);
        }
    }
}

void do_check_wo_irq(int* errors, int* src, int* dst, size_t word_n, int start) {
    for (size_t i = 0; i < word_n; ++i) {
        src[i] = start + i;
    }
    mb();

    UP_AXI_SRC_ADDR = (int)src;
    UP_AXI_DST_ADDR = (int)dst;
    UP_AXI_SIZE = REG_SIZE_GET_BYTE_SIZE(word_n * 4);
    do_check_ctrl_src_dst_size(
        errors, 
        0,
        (int)src, (int)dst,
        REG_SIZE_GET_BYTE_SIZE(word_n * 4));

    UP_AXI_CMD = UP_AXI_CMD_TRIGGER_BIT;

    // Figure out how many AXI reg accesses can happen during data processing at most.
    int busy_loops = 0;
    while(1) {
        int status = UP_AXI_STATUS;
        if (status & UP_AXI_STATUS_BUSY_BIT) {
            ++busy_loops;
            continue;
        }
        break;
    }

    {
        // Make sure status is expected;
        int status = UP_AXI_STATUS;

        if (!(status & UP_AXI_STATUS_INT_BIT)) {
            ++(*errors);
            printf("Error: status int bit should be set, but it is unset\n");
        }

        // Clear int pending
        UP_AXI_CMD = UP_AXI_CMD_CLR_INT_BIT;
        status = UP_AXI_STATUS;
        if (status & UP_AXI_STATUS_INT_BIT) {
            ++(*errors);
            printf("Error: status int bit should be unset, but it is set\n");
        }
    }

    printf("src:");
    print_array(src, word_n);
    printf("\n");

    printf("dst:");
    print_array(dst, word_n);
    printf("\n");

    printf("busy loops: %d\n", busy_loops);

    do_compare(errors, src, dst, word_n);
}

void do_check_w_irq(int* errors, int* src, int* dst, size_t word_n, int start) {
    for (size_t i = 0; i < word_n; ++i) {
        src[i] = start + i;
    }
    mb();

    g_up_int_triggers = 0;
    mb();

    // Enable interrupt
    UP_AXI_CTRL = UP_AXI_CTRL_INT_EN_BIT;
    UP_AXI_SRC_ADDR = (int)src;
    UP_AXI_DST_ADDR = (int)dst;
    UP_AXI_SIZE = REG_SIZE_GET_BYTE_SIZE(word_n * 4);
    do_check_ctrl_src_dst_size(
        errors, 
        UP_AXI_CTRL_INT_EN_BIT,
        (int)src, (int)dst,
        REG_SIZE_GET_BYTE_SIZE(word_n * 4));

    UP_AXI_CMD = UP_AXI_CMD_TRIGGER_BIT;

    while (1) {
        if (g_up_int_triggers != 0) {
            break;
        }
    }

    // Make sure status is expected
    int status = UP_AXI_STATUS;
    if (status & UP_AXI_STATUS_INT_BIT) {
        ++(*errors);
        printf("Error: status int bit should be unset, but it is set\n");
    }
    if (status & UP_AXI_STATUS_BUSY_BIT) {
        ++(*errors);
        printf("Error: status busy bit should be unset, but it is set\n");
    }

    printf("src:");
    print_array(src, word_n);
    printf("\n");

    printf("dst:");
    print_array(dst, word_n);
    printf("\n");

    do_compare(errors, src, dst, word_n);
}

// Byte: 8K
#define WORD_NUM (2 * 1024)

int g_src[WORD_NUM];
int g_dst[WORD_NUM];

void check_wo_irq(int* errors) {
    for (size_t i = 0; i < sizeof(g_src) / sizeof(g_src[0]) && i < 4; ++i) {
        do_check_wo_irq(errors, g_src, g_dst, i + 1, (i + 1) * 10);
    }
    do_check_wo_irq(errors, g_src, g_dst, sizeof(g_src) / sizeof(g_src[0]), 100);
}

void check_w_irq(int* errors) {
    //
    // Make sure no irq pending
    //
    // Disable irq within user plugin peripherals.
    UP_AXI_CTRL = 0;
    // Clear pending int
    UP_AXI_CMD = UP_AXI_CMD_CLR_INT_BIT;

    //
    // Global enable User plugin interrupt
    //
    // Clear all events
    ECP = 0xFFFFFFFF;
    // Clear all interrupts
    ICP = 0xFFFFFFFF;
    int_enable();
    IER = IER | (1 << IRQ_UP_IDX); // Enable User plugin interrupt

    int src[4];
    int dst[4];

    for (size_t i = 0; i < sizeof(src) / sizeof(src[0]) && i < 4; ++i) {
        do_check_w_irq(errors, src, dst, i + 1, (i + 1) * 10);
    }
    do_check_w_irq(errors, g_src, g_dst, sizeof(g_src) / sizeof(g_src[0]), 100);
}


int main() {
    int errors = 0;

    check_wo_irq(&errors);
    check_w_irq(&errors);

    printf("ERRORS: %d\n", errors);

    return !(errors == 0);
}
