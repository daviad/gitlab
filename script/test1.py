#!/usr/bin/env python3
# -*- coding: utf-8 -*-
__Author__ = "dxw"
__Date__ = '2018/5/3'

import gitlab

from requests.packages import urllib3
 
urllib3.disable_warnings()

# help(gitlab)
url = 'https://192.168.0.101//api/v4/projects'
# url = 'http://192.168.0.101/api/v4/projects/94'
token = 'fY_9JmHyAnPmu9uAuCuy'
gl = gitlab.Gitlab(url=url, private_token=token, ssl_verify=False)
gl.list()

# help(gl.list)
# print(gl.projects)
# help(gitlab.Gitlab)
# help(gl.projects.list)
# projects = gl.projects.list()