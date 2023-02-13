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