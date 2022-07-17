#!/usr/share/staffcop/env18/bin/python2
import os
import subprocess
import xlrd

#os.system("staffcop drm list agent")
a="list"
#prog=subprocess.check_output(["staffcop", "drm", a, "agent"])

action="enable"
guid=""
hwid=""

#subprocess.check_output(["staffcop", "drm", action, "agent", hwid])

#print(prog)

def Exel():
	exel_file = xlrd.open_workbook(filename='./lic_mgm.xlsx',encoding_override='utf-8')
	sheet = exel_file.sheet_by_index(0)
	#sheet.cell_value(1,3)

	r_data = []
	#data = []
	row_number = sheet.nrows
	column_number= sheet.ncols

	for row in range(0, row_number):
		r_data.append(str(sheet.row(row)[row]).replace("text:u'", "").replace("'",""))
	for x in r_data :
		#data = x.encode('utf-8') 
		data = x.decode('unicode_escape').encode('utf-8')
		#print (data)
	
	
	raw_data = []
	for row in range(0,row_number):
		for col in range(0,column_number):
			raw_data.append(sheet.cell_value(row,col))

	information = []
	for x in raw_data:
		information.append(str(x.encode('utf-8')).replace("text:u'", "").replace("'",""))

	#print(raw_data)
	print(information[1][1])
	#print(type(sheet.cell_value(0,0)))

	#print( '\n'.join(data) )
	#print( data )
	#print(exel_file.codepage)


Exel()
