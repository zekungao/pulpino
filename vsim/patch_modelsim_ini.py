#!/usr/bin/env python3

import configparser
import os
import shutil


def patch_coverage(config):
    def patch_one_section(sect):
        # s: statement
        # b: branch
        # c: condition
        # e: expression
        # f: fsm
        # t: toggle
        sect['Coverage'] = 'sbceft'

    # Add Coverage = sbceft
    # Sections to be patched
    sect_names = ('vcom', 'vlog', 'vopt')

    # In case some section does not exist.
    for sect_name in sect_names:
        if not config.has_section(sect_name):
            config.add_section(sect_name)

    for sect_name in sect_names:
        sect = config[sect_name]
        patch_one_section(sect)


def patch(ini_path):
    # Back up the original ini file
    # NOTE: Python ini parser does not preserve comments!!!!
    backup_path = ini_path + '.orig'
    if os.path.lexists(backup_path):
        print(f'{backup_path} exists, skip backing up')
    else:
        print(f'backing up: {ini_path} -> {backup_path}')
        shutil.copy2(ini_path, backup_path)

    config = configparser.ConfigParser()
    config.read(ini_path)
    patch_coverage(config)
    with open(ini_path, 'wt') as f:
        config.write(f)


if __name__ == '__main__':
    import argparse
    ap = argparse.ArgumentParser(description='Patch modelsim.ini')
    ap.add_argument('INI_PATH', help='path to modelsim.ini')
    args = ap.parse_args()
    patch(args.INI_PATH)
