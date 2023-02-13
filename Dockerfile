# 基于的基础镜像
FROM python:3.7.16-alpine

VOLUME ["/data", "/data"]
# 复制代码到code文件夹
COPY . ../code

# 设置code文件夹是工作目录
WORKDIR /code
RUN apk add --no-cache -U curl gcc linux-headers python python-dev libc-dev libffi-dev && \
    pip install --upgrade pip && \
    pip install -r requirements.txt && \
    apk del curl gcc linux-headers python python-dev libc-dev libffi-dev
# 申明镜像内服务监听的端口
EXPOSE 5000
CMD ["python","subworks.py"]

FROM alpine:latest

MAINTAINER Terence Fan <stdrickforce@gmail.com>

VOLUME ["/data", "/data"]

RUN mkdir -p /tmp/pycat

COPY . /tmp/pycat

WORKDIR /tmp/pycat

ENV BUILD_ESSENTIALS="curl gcc linux-headers python python-dev libc-dev libffi-dev"

RUN apk add $BUILD_ESSENTIALS && \
        curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
        python get-pip.py && rm get-pip.py && python setup.py install && \
        apk del $BUILD_ESSENTIALS && \
        pip install --upgrade pip && \
        pip install -r requirements.txt && \

WORKDIR /tmp/pycat

EXPOSE 8111
CMD ["python","subworks.py"]