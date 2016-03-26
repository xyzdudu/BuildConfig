import mysql.connector
import struct
import zlib

def connectMySQL():
	try:
		conn = mysql.connector.connect(
		host='192.168.23.4',#主机IP地址
		port=3306,#端口号
		user='root',#用户名
		password='123456',#密码
		database='zhtx_template'#数据库名
		)
		return conn
	except ZeroDivisionError as e:
		print('except:',e)

#配置表字段
def getTemplateColumnnames(cursor,templateName):
	cursor.execute('select COLUMN_NAME from information_schema.COLUMNS where table_name = %s and table_schema= %s',[templateName,'zhtx_template'])
	return cursor.fetchall()

#配置表里每个字段对应的数据类型
def getTemplateTypes(cursor,templateName):
	cursor.execute('select DATA_TYPE from information_schema.COLUMNS where table_name = %s and table_schema= %s',[templateName,'zhtx_template'])
	return cursor.fetchall()

#配置表数据
def getTemplateDatas(cursor,templateName):
	cursor.execute('select * from zhtx_template.' + templateName)
	return cursor.fetchall()

#配置表有多少条数据
def getTemplateCount(cursor,templateName):
	cursor.execute('select count(*) from zhtx_template.' + templateName)
	return cursor.fetchall()

#全部配置表
def getTemplates(cursor):
	cursor.execute('select TABLE_NAME from information_schema.TABLES where TABLE_SCHEMA = %s',['zhtx_template'])
	return cursor.fetchall()

#导出配置dgb
def writeToDgb(zlibBytes,templateName):
	f = open('./config/' + templateName + '.dgb','wb')
	f.write(zlibBytes)
	f.close()

#解析配置表，转换成二进制
def transConfigToBytes(templateName,datas,datatypes,count):
	titleLen = len(templateName.encode('utf-8'));
	bytes = struct.pack('>H%d'%titleLen+'s',titleLen,templateName.encode('utf-8'))
	bytes = bytes + struct.pack('>i',count[0][0])
	countIndex = 0
	while countIndex < count[0][0]:
		datatypesIndex = 0
		for datatype in datatypes:
			if datas[countIndex][datatypesIndex] == None:
				continue;
			if datatype[0] == 'int' or datatype[0] == 'tinyint' or datatype[0] == 'smallint':
				bytes = bytes + struct.pack('>i',datas[countIndex][datatypesIndex])
			elif datatype[0] == 'float':
				bytes = bytes + struct.pack('>f',datas[countIndex][datatypesIndex])
			elif datatype[0] == 'bigint':
				bytes = bytes + struct.pack('>d',datas[countIndex][datatypesIndex])
			elif datatype[0] == 'char' or datatype[0] == 'varchar' or datatype[0] == 'text':
				datelen = len(datas[countIndex][datatypesIndex].encode('utf-8'))
				str = '>H%d'%datelen+'s'
				bytes = bytes + struct.pack(str,datelen,datas[countIndex][datatypesIndex].encode('utf-8'))
			datatypesIndex = datatypesIndex + 1
		countIndex = countIndex + 1

	zlibBytes = zlib.compress(bytes,9)
	return zlibBytes

def buildConfig(templateName):
	datatypes = getTemplateTypes(cursor,templateName)
	count = getTemplateCount(cursor,templateName)
	datas = getTemplateDatas(cursor,templateName)

	arrTemplateName = templateName.split('_')
	arrTemplateName.pop()
	arrTemplateName.pop(0)
	titleName = ''
	i = 0;
	for name in arrTemplateName:
		if i == 0:
			titleName = titleName + name
		else:
			titleName = titleName + name.title()
		i = i + 1
	titleName = titleName + 'List'

	bytes = transConfigToBytes(titleName,datas,datatypes,count)
	writeToDgb(bytes,titleName)


if __name__ == '__main__':

	conn = connectMySQL()
	cursor = conn.cursor()

	arrTemplates = getTemplates(cursor)
	for template in arrTemplates:
		templateName = template[0]
		buildConfig(templateName)

	print('导出完成')

	cursor.close()
	conn.close()