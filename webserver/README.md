# Run the server

## Prequisites

Like at the setup, anisette still needs to run to be able to fetch reports with the proxy

**Important:** the anisette server needs to cast the same static information as at the registration!

You'll also need to [generate](../token-generator/README.md) the openhaystack.json
If you already generated it, you're good to go, since it's symlinked if you didn't changed the config

## Start the Server

### Native

Install requirements

~~~
pip3 install -r requirements.txt
~~~

start the server

~~~
python3 FindMy_proxy.py
~~~

### Docker

~~~
docker build --no-cache --squash -t headless-haystack .
~~~

~~~
docker run -it --rm -p 6176:6176 -v ./openhaystack.json:/root/openhaystack.json headless-haystack-proxy:latest
~~~

### Docker compose

If you want to run anisette in this directory

~~~
mkdir anisette-data
~~~

Run the Server

~~~
docker-compose up -d
~~~

*Note: you may close the port anisette is listening on, since the container can connect to anisette anyway*