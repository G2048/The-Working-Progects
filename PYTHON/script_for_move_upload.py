#!/usr/share/staffcop/env18/bin/python2

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

    def __init__(self,dbname='staffcop'):
        self.password = self.get_password()
        self.connect_db(self.password,dbname)

    def get_password(self):
        with open('/etc/staffcop/config', 'r') as f:
            strings = f.read()
            self.result = re.findall("(?<='PASSWORD': ')(.*)(?=',)", strings) 
            return self.result[0]

    def connect_db(self,password,dbname):
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

def update_data(db_name, select, def_path='/var/lib/staffcop/upload/', flag=True):
    get_folders = """
        SELECT DISTINCT substring(att.data from '\d{4}_\d{2}_\d{2}/') 
        FROM agent_event ae 
        LEFT JOIN agent_attachedfile att 
            ON ae.attached_file_id = att.id 
        WHERE att.data LIKE 'file%'
        """

    for cold_database in db_name:
        count = 0
        con = Data_Bases(cold_database)

        con.request(select)
        attach_files = con.fetch()

        con.request(get_folders)
        folders = con.fetch()
    
        #Create a full path to coldbase storage like /var/lib/staffcop/upload/staffcop2
        if flag is True :
            middle_path = def_path + cold_database 
        else :
            middle_path = "filedata/by_date" #If flag is false then the "filedata/" path is default 
            
        #Move on the files
        for folder in folders :
            old = '{}filedata/by_date/{}'.format(def_path,folder)
            new = '{}/{}'.format(middle_path,folder)
            try:
                #os.renames(old, new)
                print 'Directory {} was moved to {}'.format(old,new)
            except :
                print 'Directory {} does not exist!\n'.format(old)

        #Make absolyte path to file ##/var/lib/staffcop/upload/staffcop2/2022_04_06/c2695b75d0c85acd06d5b4a6c7d53207a20ae7ec.png
        for clear_file in attach_files :
            new_absolute_path_to_file = '{}/{}'.format(middle_path,clear_file) 

            #Updating links into DB
            update_query = "UPDATE agent_attachedfile SET data='{}' WHERE data LIKE '%{}';".format(new_absolute_path_to_file,clear_file) #clear_file is search condition

            #con.request(update_query)
            #print update_query
            count = count + 1

        con.com()
        con.close_con()
        print "\n\n{} Links into Database {} Updated!\n".format(count,cold_database)



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
    WHERE att.data ~ '^f'
    """


#Connect and get cold DB names 
con = Data_Bases()
con.request(select_dbname)
db_name = con.fetch()
con.close_con

update_data(db_name, select_old_data)
#update_data(db_name, path, select_old_data, False)
