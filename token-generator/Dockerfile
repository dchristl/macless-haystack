FROM python:3-alpine

RUN apk add --no-cache cmake make g++ pkgconfig linux-headers

COPY pypush/ /root/pypush/

WORKDIR /root/pypush

RUN sed -i 's|ANISETTE = False|import netifaces\nANISETTE = "http://" + netifaces.gateways()["default"][netifaces.AF_INET][0] + ":6969/"|' icloud/gsa.py

RUN MAKEFLAGS="-j$(nproc)" pip3 install -r requirements.txt
RUN pip3 install asn1crypto netifaces
RUN apk del cmake make g++ pkgconfig linux-headers

ENTRYPOINT [ "/usr/local/bin/python", "examples/openhaystack.py" ]