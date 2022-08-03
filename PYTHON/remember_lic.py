#!/usr/share/staffcop/env18/bin/python2
#Created by FW_IX

import subprocess
import argparse
from enum import Enum
from sys import stdout

def cli_parser():
    parser = argparse.ArgumentParser(formatter_class=argparse.RawDescriptionHelpFormatter, add_help=False, 
            description = """This is script created for exporting and importing agents and accounts licenses.
        You have to use option '--export' to export and agents and accounts licenses. 
        After that you have to use option '--import' to import either agents or accounts licenses.

If you want to remove licenses or to select agents or accounts with released, you have add key '--remove'.
    Examples:
        ./remember_lic.py --export --remove 
        ./remember_lic.py --import --remove
                        """)

    exclusion_group = parser.add_argument_group('Primary action', 'Use to select actions. This selection is mutually exclusive!')
    exclusion_group.add_argument('-e', '--export', dest='dump', action='store_true', required=False, 
                                help='''Create two export files "export_lic_account.txt" and "export_lic_agent.txt" 
                                        with agents/accounts licens in curent directory
                                ''')
    exclusion_group.add_argument('-i', '--import', dest='person', choices=['agent', 'account'], 
                                required=False, help='Allocate agents/accounts licens')

    parser.add_argument('-r', '--remove', dest='action', action='store_false', required=False, help='Remove licenses (Optional)')
    parser.add_argument('-h', '--help', dest='help', action='help', 
                        help='Show this help message and exit.')

    return parser.parse_args()


def export_lic(flag):
    numbers_files = 0
    condition = int('-1')
    persons = ('agent', 'account')

    #Select removed or allocated licenses
    if flag is True:
        action = 'Yes'
    else:
        action = 'No'

    for person in persons:
        file_name = 'export_lic_' + person + '.txt'

        raw_output = subprocess.check_output(["staffcop", "drm", "list", person]).decode('utf-8')
        output = raw_output.split('\n')[:-1]        #Why it isn't split? [:-1] using for deleting last empty string

        #Clearing file before as writing
        with open(file_name, 'w') as op:
            op.write('')

        with open(file_name, 'a+') as op:
            for line in output:
                try:
                    line_dict = filter(lambda x: x != '', line.split(' '))
                    check = line_dict[1].find(action)               #Check enabled or not licens
                    check_long_guid = line_dict[0].find(action)     #For long SID 
                    # if check != condition:
                    if (check != condition) or (check_long_guid != condition):
                        op.write(line_dict[0] + '\n')       #Write guid in file
                except Exception as e:
                    print e

def import_lic(flag_action, person):
    file_name = 'export_lic_' + person + '.txt'

    if flag_action is True:
        handler= 'enable'
        action = 'allocate'
    else:
        handler = 'disable'
        action = 'release'

    with open(file_name, 'r') as op:
        for lic in  op.readlines():
            guid = lic.split('\n')[0]

            subprocess.call(["staffcop", "drm", handler , person, guid])
            subprocess.call(["staffcop", "drm", action , person, guid])

class Actions(Enum):

    STATUS_EXPORT = True
    STATUS_ENTITY = None


#--Start Code of This--#
args = cli_parser()

if args.dump is Actions.STATUS_EXPORT.value:
    export_lic(flag = args.action)

elif args.person is not Actions.STATUS_ENTITY.value:       #Check existing agent/accounts entity
    import_lic(flag_action = args.action, person = args.person)
else:
    print "You have add the '--help' key to view the options"
    # args.help
