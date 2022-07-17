#!/usr/share/staffcop/env18/bin/python2

import argparse
import psycopg2
import os
import pwd
import grp
import re 

def create_dir(dir_name='archive', you_path='/var/lib/staffcop/upload/' ):
    #print dir_name
    #print you_path
    try:
        os.chdir(you_path)
    except:
        create_dir(you_path)

    if not os.path.isdir(dir_name):
        os.mkdir(dir_name,0o755)
        uid = pwd.getpwnam("staffcop").pw_uid
        gid = grp.getgrnam("staffcop").gr_gid
        os.chown(dir_name, uid, gid)
    else:
        print "Already Directory!"


class Data_Bases:

    def __init__(self, dbname='staffcop'):
        self.password = self.get_password()
        self.connect_db(self.password,dbname)

    def get_password(self):
        with open('/etc/staffcop/config', 'r') as f:
            strings = f.read()
            self.result = re.findall("(?<='PASSWORD': ')(.*)(?=',)", strings) 
            return self.result[0]

    def connect_db(self, password, dbname):
        self.conn = psycopg2.connect("dbname={1} user=staffcop password={0}".format(password,dbname))
        self.cur = self.conn.cursor()
        print "DataBase is Open!\n"

    def request(self, sql): 
        self.cur.execute(sql)

    def fetch(self):
        return [item for tuple_ in self.cur.fetchall() for item in tuple_]

    def com(self):
        self.conn.commit()

    def close_con(self):
        self.cur.close()


    def __del__(self):
        self.conn.close()
        print "\nDataBase is Closed\n"

class Update:

    def __init__(self, cold_database, def_path='/var/lib/staffcop/upload/', flag=''):
        self.con = Data_Bases(cold_database)
        #self.atttach_files = self.get_data(select,path)
        self.path = def_path
        self.flag = flag

        #Create a full path to coldbase storage like /var/lib/staffcop/upload/staffcop_archive
        if flag is '':
            self.middle_path = self.path + cold_database 
        else :
            self.middle_path = "filedata/by_date" #If flag is false then the "filedata/" path is default 


    def get_data(self, select):
        count = 0

        self.con.request(select)
        self.attach_files = self.con.fetch()
        con.close_con
        return self.attach_files 

    def get_folders(self):
        select_folders = """
            SELECT DISTINCT substring(att.data from '\d{4}_\d{2}_\d{2}/') 
            FROM agent_event ae 
            LEFT JOIN agent_attachedfile att 
                ON ae.attached_file_id = att.id 
            WHERE att.data %s LIKE 'file%%'
            """ % self.flag

        self.con.request(select_folders)
        self.folders = self.con.fetch()
        return self.folders
    
           
    #Move on the files
    def move_files(self):
        for folder in self.get_folders():
            old_path = '{}filedata/by_date/{}'.format(self.path,folder)
            new_path = '{}/{}'.format(self.middle_path,folder)
            try:
                #os.renames(old, new)
                print 'Directory {} was moved to {}'.format(old_path,new_path)
            except :
                print 'Directory {} does not exist!\n'.format(old_path)

    def update_links(self):
        #Make absolyte path to file ##/var/lib/staffcop/upload/staffcop2/2022_04_06/c2695b75d0c85acd06d5b4a6c7d53207a20ae7ec.png
        for clear_file in attach_files :
            new_absolute_path_to_file = '{}/{}'.format(self.middle_path,clear_file) 

            #Updating links into DB
            update_query = "UPDATE agent_attachedfile SET data='{}' WHERE data LIKE '%{}';".format(new_absolute_path_to_file,clear_file) #clear_file is search condition

            #con.request(update_query)
            #print update_query
            count = count + 1

        con.com()
        con.close_con()
        print "\n\n{} Links into Database {} Updated!\n".format(count,cold_database)


parser = argparse.ArgumentParser(description='Do it!')
subparsers = parser.add_subparsers(title='subcommands',
                                   description='valid subcommands',
                                   help='description')
get_parser = subparsers.add_parser('')
#parser.add_argument('--freeze', dest='flag', default='')
#parser.add_argument('--antifreeze', dest='flag', default='NOT', required=False)
args = parser.parse_args()
flag = args.flag

#VARIABLES
#select_tablespace = "SELECT spcname FROM pg_tablespace WHERE spcname NOT IN ('pg_default', 'pg_global');"
select_dbname = """
   SELECT datname 
   FROM pg_database db 
   LEFT JOIN pg_tablespace tbsp 
      ON tbsp.oid=db.dattablespace 
   WHERE tbsp.spcname 
   NOT IN ('pg_default','pg_global')
   """

select_old_data = """
    SELECT substring(att.data from '\d{4}_\d{2}_\d{2}/\w+\.\w{3,}') 
    FROM agent_event ae 
    LEFT JOIN agent_attachedfile att 
        ON ae.attached_file_id = att.id 
    WHERE att.data %s LIKE 'file%%'
    """ % flag


#Connect and get cold DB names 
con = Data_Bases()
con.request(select_dbname)
db_name = con.fetch()
con.close_con

for database in db_name:
    up = Update(database, flag=flag)
    data = up.get_data(select_old_data)
    print up.get_folders()
    print up.move_files()
    #print data
