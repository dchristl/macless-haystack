FROM python:slim


ENV TERM xterm
WORKDIR /endpoint

COPY . /endpoint
RUN apt-get update && apt-get install -y curl nano iproute2 
RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

CMD ["python", "mh_endpoint.py"]