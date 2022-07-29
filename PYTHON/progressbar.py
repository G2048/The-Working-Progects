#!/usr/share/staffcop/env18/bin/python2

from sys import stdout
# import time


def progress_bar(end):
    spinner = "/-\|"
    for start in range(end + 1):
        GREEN = '\033[0;32m'
        NC='\033[0m'
        lenght = 10
        k = 5
        progress = start * 100 / end
        left = progress * k / lenght 
        right = lenght * k - left
        spin = spinner[ start % 4 ]
        # sys.stdout.write("\rProgress : [ {} {} ] {}% ".format( left * '#', right * '-', progress ) )
        stdout.write("\r%sProgress :%s [ %s%s ] %s %d%% " % ( GREEN, NC, left * '#', right * '-',spin ,progress ) )
        # time.sleep(0.01)
    stdout.write("\n")    

progress_bar(20000000)
