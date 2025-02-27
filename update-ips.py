#!/usr/bin/env python
# Francesco Conti <f.conti@unibo.it>
#
# Copyright (C) 2016 ETH Zurich, University of Bologna.
# All rights reserved.

import sys,os,subprocess,re
import argparse

devnull = open(os.devnull, 'wb')

def execute(cmd, silent=False):
    if silent:
        stdout = devnull
    else:
        stdout = None
    return subprocess.call(cmd.split(), stdout=stdout)

def execute_out(cmd, silent=False):
    p = subprocess.Popen(cmd.split(), stdout=subprocess.PIPE)
    out, err = p.communicate()
    return out

def find_server():
    stdout = execute_out("git remote -v")

    stdout = stdout.split('\n')
    for line in stdout:
        if "origin" in line:
            tmp = line.split(' ')
            tmp = tmp[0].split('\t')

            remote = tmp[1]

            if "https://" in remote:
                # first remove the https, we'll put it back later
                remote = remote[8:]

                # now we have to remove the pulpino.git suffix and figure out the group
                tmp = remote.split('/', 2)
                server = "https://%s" % (tmp[0])
                group = tmp[1]
                remote = "%s/%s" % (server, group)
            else:
                # now we have to remove the pulpino.git suffix and figure out the group
                remote =  remote.rsplit('/', 1)[0]
                tmp = remote[::-1]
                tmp = re.split(r'[:/]', tmp, 1)
                server = tmp[1][::-1]
                group = tmp[0][::-1]

            return [server, group, remote]

    print tcolors.ERROR + "ERROR: could not find remote server." + tcolors.ENDC
    sys.exit(1)


ap = argparse.ArgumentParser(
    description='Fetch dependent IPs')
ap.add_argument('remote', nargs='?', help='git remote server')
args = ap.parse_args()

if args.remote is None:
    _, _, remote = find_server()
else:
    remote = args.remote


print "Using git remote %s" % (remote,)


# download IPApproX tools in ./ipstools and import them
if os.path.exists("ipstools") and os.path.isdir("ipstools"):
    cwd = os.getcwd()
    os.chdir("ipstools")
    execute("git pull origin verilator-pulpino", silent=True)
    os.chdir(cwd)
    import ipstools
else:
    # try to find the ipstools repository
    execute("git clone %s/IPApproX.git ipstools -b verilator-pulpino" % (remote))
    import ipstools

# creates an IPApproX database
ipdb = ipstools.IPDatabase(ips_dir="./ips", skip_scripts=True)
# updates the IPs from the git repo
ipdb.update_ips(remote = remote)

# launch generate-ips.py
execute("./generate-scripts.py")
