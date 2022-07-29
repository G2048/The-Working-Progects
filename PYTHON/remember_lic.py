#!/usr/share/staffcop/env18/bin/python2

import subprocess
import argparse
from sys import stdout

def export_lic(flag):
    condition = int('-1')
    persons = ['agent', 'account']

    #Select removed or allocated licenses
    if flag is True:
        action = 'Yes'
    else:
        action = 'No'

    for person in persons:
        file_name = 'export_lic_' + person + '.txt'

        raw_output = subprocess.check_output(["staffcop", "drm", "list", person]).decode('utf-8')
        output = raw_output.split('\n') #Why default way don't split?

        #Clearing file before as writing
        with open(file_name, 'w') as op:
            op.write('')

        with open(file_name, 'a+') as op:
            for line in output:
                try:
                    line_dict = filter( lambda x: x != '', line.split(' '))
                    check = line_dict[1].find(action) #Check enabled licens
                    if check != condition:
                        op.write(line_dict[0] + '\n') #Write guid in file
                except Exception as e:
                    print e


def import_lic(flag, person):
    file_name = 'export_lic_' + person + '.txt'

    if flag is True :
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

def progress_bar(end): 
    for start in range(end + 1): 
        lenght = 10 
        k = 5 
        progress = start * 100 / end 
        left = progress * k / lenght 
        right = lenght * k - left 
        stdout.write("\rProgress : [ {} {} ] {}% ".format( left * '#', right * '-', progress ) ) 
    stdout.write("\n")

#--Start Code of This--#
parser = argparse.ArgumentParser(formatter_class=argparse.RawDescriptionHelpFormatter,
        description = """This is script created for export/import licens.
    You must use option '--export' for export and agents and accounts licenses. 
    Next step, this is using option '--import' either agents or accounts licenses.

If you want remove or select a removed licenses choose key '--remove'. 
    Examples:
        ./remember_lic.py --export --remove 
        ./remember_lic.py --import --remove""")

exclusion_group = parser.add_argument_group('Primary action', 'Use to select actions')

exclusion_group.add_argument('-e', '--export', dest='dump', action='store_true', 
        required=False, help='Create two export files "export_lic_account.txt" and "export_lic_agent.txt"  with agents/accounts licens in curent directory')

exclusion_group.add_argument('-i', '--import', dest='person', choices=['agent', 'account'],
        required=False, help='Allocate agents/accounts licens')

parser.add_argument('-r', '--remove', dest='action', action='store_false', required=False, help='Remove licenses (Optional)')

args = parser.parse_args()

if args.dump is True:
    export_lic(flag=args.action)
elif args.person is not '':
    import_lic(flag=action, person=args.person) # If you want remove licenses choosing flag=False
else:
    parser.print_help()
