# 基于的基础镜像
FROM python:3.7.16-alpine

VOLUME ["/data", "/data"]
# 复制代码到code文件夹
COPY . ../code
ENV BUILD_ESSENTIALS="curl gcc linux-headers python python-dev libc-dev libffi-dev"
# 设置code文件夹是工作目录
WORKDIR /code
RUN apk add $BUILD_ESSENTIALS && \
    pip install --upgrade pip && \
    pip install -r requirements.txt && \
    apk del $BUILD_ESSENTIALS
# 申明镜像内服务监听的端口
EXPOSE 5000
CMD ["python","subworks.py"]