# 基于的基础镜像
FROM python:3.7.16-alpine
# 复制代码到code文件夹
COPY . ../code
# 设置code文件夹是工作目录
WORKDIR /code
RUN apk add --update --no-cache && \
    pip install --upgrade pip && \
    pip install -r requirements.txt
# 申明镜像内服务监听的端口
EXPOSE 5000
CMD ["python","subworks.py"]