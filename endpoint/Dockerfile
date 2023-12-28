FROM python:slim

EXPOSE 6176

WORKDIR /webserver

COPY . /webserver
RUN apt-get update && apt-get install -y curl
RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

CMD ["python", "mh_endpoint.py"]