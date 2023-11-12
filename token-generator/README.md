# Generate the access token

## Overview

To be able to fetch data from the servers, you need a working anisette Server and a working access token.

**Important:** the anisette server needs to cast the same static information as at the registration!

If you dont have an anisette server running, you may go to [../webserver](../webserver) and run

~~~
docker compose up -d anisette
~~~

that will only start anisette so you can register and anisette generates the needed files in the right directory

## Prequisites

like mentioned, you'll need a anisette server which accepts Connections from `0.0.0.0:6969`

## Generating the token

You either need to install pypush's dependencies, modify the anisette server to use

~~~
sed -i 's|ANISETTE = False|ANISETTE = "http://127.0.0.1:6969/"|' pypush/icloud/gsa.py && mkdir pypush/config
~~~

and run

~~~
cd pypush; python3 examples/openhaystack.py; cd ..
~~~

or use the Dockerfile to build a container

~~~
docker build --no-cache --squash -t openhaystack-token-generator .
~~~

after that run

~~~
docker run -it --rm -v ./config/:/root/pypush/config/ openhaystack-token-generator:latest
~~~

*Note: in my particular case, I couldn't get pypush work directly, so I decided to create the dockerfile*

## Using the token

go to [webserver](../webserver/README.md)
