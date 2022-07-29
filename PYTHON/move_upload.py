#!/usr/share/staffcop/env18/bin/python2

import argparse
import psycopg2
import os
import pwd
import grp
import re 

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
        # self.conn.close()
        print "\nDataBase is Closed\n"

class Update:

    def __init__(self, cold_database, def_path='', flag=''):
        self.con = Data_Bases(cold_database)

        # If you want move files from the cold storage
        self.flag = flag
        self.name_database = cold_database

        #Create a full path to coldbase storage like /var/lib/staffcop/upload/staffcop_archive
        if flag is '':
            self.middle_path = def_path + self.name_database
            self.flag_path_to_folder = self.middle_path
            self.primary_dir = '/var/lib/staffcop/upload/filedata/by_date/'
            self.flag_select_condition = ''
        # If you want to move files from the cold storage
        else :
            self.primary_dir = def_path
            self.middle_path = 'filedata/by_date' #If flag is false then the "filedata/" path is default 
            self.flag_path_to_folder = '/var/lib/staffcop/upload/' + self.middle_path 
            self.flag_select_condition = "AND att.data ~ '%s'" % self.name_database

    def get_data(self, select):

        self.con.request(select)
        self.attach_files = self.con.fetch()
        # con.close_con
        return self.attach_files 

    def get_folders(self):
        select_folders = """
            SELECT DISTINCT substring(att.data from '/\d{4}_\d{2}_\d{2}/') 
            FROM agent_event ae 
            LEFT JOIN agent_attachedfile att 
                ON ae.attached_file_id = att.id 
            WHERE att.data %s LIKE 'file%%' %s
            """ % (self.flag, self.flag_select_condition)

        # import pdb; pdb.set_trace()
        self.con.request(select_folders)
        self.folders = self.con.fetch()
        return self.folders


    def create_dir(self, path='', dir_name=''):

        if os.path.isdir(path):
            os.chdir(path)
        elif path is not '' :
            self.create_dir(dir_name=path)
            os.chdir(path)

        if not os.path.isdir(dir_name):
            os.mkdir(dir_name,0o755)
            uid = pwd.getpwnam("staffcop").pw_uid
            gid = grp.getgrnam("staffcop").gr_gid
            os.chown(dir_name, uid, gid)
        else:
            print "Already Directory!"


    #Move on the files
    def move_files(self):
        # import pdb; pdb.set_trace()
        for folder in self.get_folders():
            old_path = '{}{}'.format(self.primary_dir, folder)
            new_path = '{}{}'.format(self.flag_path_to_folder, folder)

            self.create_dir(path=self.flag_path_to_folder, dir_name=folder)

            try:
                os.renames(old_path, new_path)
                print 'Directory {} was moved to {}'.format(old_path, new_path)
            except Exception as e :
                print '{} {} !\n'.format(e, old_path)

    def update_links(self):
        count = 0
        #Make absolyte path to file ##/var/lib/staffcop/upload/archive_db/2022_04_06/c2695b75d0c85acd06d5b4a6c7d53207a20ae7ec.png
        for clear_file in self.attach_files :
            new_absolute_path_to_file = '{}/{}'.format(self.middle_path, clear_file) 

            #Updating links into DB
            update_query = "UPDATE agent_attachedfile SET data='{}' WHERE data LIKE '%{}';".format(new_absolute_path_to_file, clear_file) #clear_file is search condition

            self.con.request(update_query)
            count = count + 1

        self.con.com()
        # self.con.close_con()
        print "\n\n{} Links into Database {} Updated!\n".format(count,self.name_database)

# Start code of this
parser = argparse.ArgumentParser(formatter_class=argparse.RawDescriptionHelpFormatter, 
        description="""This is the scrip created for updating and move files from Database and filestorage into cold storage 
        Example : ./move_upload.py --path /mnt/cold_upload""") 

parser.add_argument('-a', '--antifreeze', action='store_true', required=False, help='Go to back files')
parser.add_argument('-p', '--path', action='store_true', required=False, help='Move file into specified storage')
args = parser.parse_args()

if args.path:
    path = path + '/'
else:
    path = '/var/lib/staffcop/upload/filedata/by_date/colds_files/'


#For move to files from cold storage into default path
if args.antifreeze:
    flag = 'NOT'
else:
    flag = ''


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

# Updating links inside DataBase
for database in db_name:
    up = Update(database, def_path=path, flag=flag)
    up.get_data(select_old_data)
    # try:
    up.move_files()
    up.update_links()
    # except Exception as e:
        # print "Error : %s" % e
        # raise SystemExit
