#!/usr/share/staffcop/env18/bin/python2

import psycopg2
import os.path

password='ac11f61f9d6c4239d837e75d010cd2076c6b56ba8c5e2ae0298e94cf20c626c3'
conn = psycopg2.connect("dbname=staffcop user=staffcop password={}".format(password))

cur = conn.cursor()
cur.execute("SELECT data FROM agent_attachedfile;")
data = cur.fetchall()

cur.close()
conn.close()
print "DataBase Closed"

full_path = '/var/lib/staffcop/upload/filedata/by_date/'
db_exists_files = []
db_non_exists_files = []

def_path='/var/lib/staffcop/upload/'
piece_path = ''

for i in range(len(data)):
	if data[i][0].startswith(tuple('filedata')):

		full_string = "{}{}".format(def_path,data[i][0])
		#print full_string
	else :
		piece_path =  data[i][0].split('filedata')[0]
		#print another_path
		full_string = "{}".format(data[i][0])

	if  os.path.exists(full_string):
		db_exists_files.append(full_string)
	else:
		db_non_exists_files.append(full_string)


#print os.listdir(full_path)
print "Total Exist Files From DB: {}".format(len(db_exists_files))
print "Total Nonexist Files From DB: {}\n".format(len(db_non_exists_files))

def Pull_files(path):

	array_files = []
	for i in os.listdir(path):
		#print full_path + i
		if os.path.isdir(path + i):
			for j in os.listdir(path + i):
				#print path + i + "/" + j
				array_files.append(path + i + '/' + j)
		#elif  os.path.isfile(path + i):

	return array_files


def_storage_files = Pull_files(full_path)
storage_files = def_storage_files

if os.path.isdir(piece_path):
	external_path = piece_path + 'filedata/by_date/'
	external_storage_files = Pull_files(external_path)
	storage_files = def_storage_files + external_storage_files


#for i in range(len(storage_files)):
#	print storage_files[i]

if os.path.isdir(piece_path):
	print "Total number Files into External Storage {}".format(len(external_storage_files))

print "Total number Files into Default Storage {}".format(len(def_storage_files))
print "Total Exist Files From Storage: {}\n".format(len(storage_files))

set_db_exists_files = set(db_exists_files)
set_storage_files = set(storage_files)

print "Size of SET DB: {}".format(len(set_db_exists_files))
print "Size of SET Storage: {}".format(len(set_storage_files))


#files_for_deleting = set_storage_files - set_db_exists_files
files_for_deleting = set_storage_files.difference(set_db_exists_files)
#files_for_deleting2 =  set_db_exists_files - set_storage_files

print "\nOrfaned Files Into Storage: {}".format(len(files_for_deleting))
#print len(files_for_deleting2)

#for i in files_for_deleting:
#	print i

def Deleting(supply):
	count = 0
	for path in supply:
		#os.remove(path)
		print path
		count += 1
	return count

choose = raw_input('Are you Want to delete files? (Yes/No) ')

if ("y" or "Y") in choose:
	print "DELETING {} Files.".format(Deleting(files_for_deleting))

