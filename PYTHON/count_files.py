#!/usr/share/staffcop/env18/bin/python2

import psycopg2
import os.path
import re
from datetime import datetime 
import time 
start_time = datetime.now()


full_path = '/var/lib/staffcop/upload/filedata/by_date/'
db_exists_files = set()

def_path='/var/lib/staffcop/upload/'
piece_path = ''
select = "SELECT data FROM agent_attachedfile"

def Get_pass():
    with open('/etc/staffcop/config', 'r') as f:
            strings = f.read()
            result = re.findall("(?<='PASSWORD': ')(.*)(?=',)", strings)
    return result[0]


class Data_Bases:

    def __init__(self, password):
        conn = psycopg2.connect("dbname=staffcop user=staffcop password={}".format(password))
        self.cur = conn.cursor()
        print "DataBase is open"

    def request(self, sql):
        self.cur.execute(sql)
        return self.cur.fetchall()

    def close_con(self):
        self.cur.close()
        self.conn.close()
        print "\nDataBase is Closed\n"

def Pull_files(path):
    array_files = set()
    for i in os.listdir(path):
        #print full_path + i
        if os.path.isdir("{}{}".format(path,i)):
            for j in os.listdir("{}{}".format(path, i)):
                #print "{}{}/{}".format(path, i, j)
                array_files.add("{}{}/{}".format(path, i, j))
        #elif  os.path.isfile(path + i):
    return array_files

def Deleting(supply):
    count = 0
    for path in supply:
        try:
            os.remove(path)
            print "{} deleting!".format(path)
            count += 1
        except Exception as e:
            count -= 1
            print e
    return count


password = Get_pass()
connection = Data_Bases(password)
raw_files = connection.request(select)
connection.close_con


## Unwrap raw data from DB ##
for i in raw_files :
    for j in i :
        if j.startswith(tuple('filedata')) :
                full_string = "{}{}".format(def_path, j)
        else :
            if len(piece_path) == 0:
                piece_path =  j.split('filedata')[0]
            full_string = "{}".format(j)
        db_exists_files.add(full_string)

print "Total Files From DB: {}".format(len(db_exists_files))


##Pull files from storage
def_storage_files = Pull_files(full_path)
size_def_storage = len(def_storage_files)

if os.path.isdir(piece_path):
	external_path = '{}filedata/by_date/'.format(piece_path)
	external_storage_files = Pull_files(external_path)
        for i in external_storage_files :
            def_storage_files.add(i)
	print "Total number Files into External Storage: {}".format(len(external_storage_files))



print "Total number Files into Default Storage: {}".format(size_def_storage)
print "Total Exist Files From Storage: {}\n".format(len(def_storage_files))

files_for_deleting = def_storage_files.difference(db_exists_files)
#files_for_deleting2 =  set_db_exists_files - set_storage_files

print "\nOrfaned Files Into Storage: {}".format(len(files_for_deleting))

choose = raw_input('Are you Want to delete files? (Yes/No) ')
if ("y" or "Y") in choose:
	print "DELETING {} Files.".format(Deleting(files_for_deleting))

print(datetime.now() - start_time)
