#coding:utf-8
import json
# import urllib.request
import requests

import sys
# reload(sys)
# sys.setdefaultencoding('utf-8')

def sendmsg(text):
    #1、构建url
    # bot_url = "https://oapi.dingtalk.com/robot/send?access_token=dec2f10d7f4da3faa8fdafdf6d707472e530a1d62c1eb4c894bd459e7f71fa51"   #url为机器人的webhook
    bot_url =  "https://oapi.dingtalk.com/robot/send?access_token=f016ebbdfc6c99b1e2be62457d02f80e0f8a65f89da116a5276fa4d5f2aa3bc4"
    #2、构建一下请求头部
    header = {
        "Content-Type": "application/json",
        "Charset": "UTF-8"
    }
    #3、构建请求数据
    # coding: utf-8
    data = {
        "msgtype": "text",
        "text": {
            "content": text
        },
        "at": {
            "atMobiles": [
                # "18067320207",

            ],
            "isAtAll": False     #@全体成员（在此可设置@特定某人）
        }
    }

    #4、对请求的数据进行json封装
    sendData = json.dumps(data)#将字典类型数据转化为json格式
    sendData = sendData.encode("utf-8") # python3的Request要求data为byte类型

    #5、发送请求
    #request = urllib.request.Request(url=url, data=sendData, headers=header)
    rsp = requests.post(url=bot_url, data=sendData, headers=header)

    #6、将请求发回的数据构建成为文件格式

    # opener = urllib.request.urlopen(request)
    #7、打印返回的结果
    print(rsp.text)
    return rsp.text
# sendmsg("你好：")

# wget --post-data="msgtype=text&text=hello"  https://oapi.dingtalk.com/robot/send?access_token=dec2f10d7f4da3faa8fdafdf6d707472e530a1d62c1eb4c894bd459e7f71fa51