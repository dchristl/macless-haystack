FROM python:slim


ENV TERM xterm
WORKDIR /app

RUN apt-get update && apt-get install -y curl nano iproute2 git cron
# Clone endpoint-folder
RUN git init
RUN git remote add origin https://github.com/dchristl/headless-haystack.git
RUN git config core.sparseCheckout true
RUN echo "endpoint" >> .git/info/sparse-checkout
RUN git pull origin macless
# Configure python
RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r endpoint/requirements.txt
# Update server files daily
RUN echo "* * * * * root /app/endpoint/cronjob" > /etc/cron.d/cronjob
RUN chmod 0644 /etc/cron.d/cronjob
RUN ls -alR
# RUN endpoint/cronjob

CMD ["python", "endpoint/mh_endpoint.py"]