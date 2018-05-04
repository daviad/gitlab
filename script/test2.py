#!/usr/bin/env python3
#-*- coding: utf-8 -*-
__Author__ = "dxw"
__Date__ = '2018/5/3'

import requests
from requests.packages import urllib3
urllib3.disable_warnings()

host = 'https://192.168.0.101//api/v4/'
url = host+'projects'
# url = 'http://192.168.0.101/api/v4/projects/94'
token = 'fY_9JmHyAnPmu9uAuCuy'
headers = {'Private-Token':token}

# url = url+'?private_token='+token+'&per_page=50'
# r = requests.get(url,verify=False)

projects = requests.get(url,headers=headers,verify=False)

# data = projects.json()
# for project in data:
# 	if project['id'] == 94:
# 		print(project) 

# fileArchive = requests.get(host+'projects/94/repository/archive',headers=headers,stream=True,verify=False)
# # print(fileArchive.content)
# f = open('./file.gzip','wb')
# for chunk in fileArchive.iter_content(chunk_size=512):
# 	if chunk:
# 		f.write(chunk)

# import gzip

# g = gzip.GzipFile(mode="rb", fileobj=open('./file.gzip', 'rb')) # python gzip 解压

# open("./unzip", "wb").write(g.read())
# # g.close()

## python调用Shell脚本，有两种方法：os.system(cmd)或os.popen(cmd),前者返回值是脚本的退出状态码，后者的返回值是脚本执行过程中的输出内容。实际使用时视需求情况而选择。 
import os
# import gitlab2

test = os.system('./gitlab2.sh')
print(test)


