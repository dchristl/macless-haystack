FROM python:3-alpine

COPY FindMy_proxy.py /root/
COPY requirements.txt /root/

WORKDIR /root/

RUN pip3 install -r requirements.txt

ENTRYPOINT [ "/usr/local/bin/python", "/root/FindMy_proxy.py" ]
