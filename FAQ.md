
## Frequently asked questions

#### Where and what data is stored on the host?

During the installation, a Docker volume (*mh_data*) is created, which is located in the default folder. This is normally under `/var/lib/docker/volumes/mh_data/_data`, but you can check, if your location is different, with:

```
docker inspect macless-haystack | grep mh_data
```
Check out the *Source*-key. The folder is typically protected and can only be accessed and modified by the root user.

In the folder you'll find the configuration (config.ini), the authentication (auth.json), if it has already been executed. Additionally, the self-signed certificate used for SSL is also located here.

#### How can I see the logs?

You can check out the logs with:
```
docker logs -f macless-haystack
```
or restart docker in interactive mode:
```
docker stop macless-haystack
docker start -ai macless-haystack
```

#### What is the config.ini used for?

This is where specific settings can be configured, for example, if another/existing Anisette server is to be used or if you want to provide a username and password. Normally, no adjustments should be necessary here.

#### Error during registration

During the registration, an error occurs, for example:

```
It seems your account score is not high enough. Log in to https://appleid.apple.com/ and add your credit card (nothing will be charged) or additional data to increase it.
```

This can happen with new accounts that have not provided any data and/or devices. A solution might be to add a payment method (i.e. credit card), register your account with a real Apple device and/or add some more data to the account at [Apple](https://appleid.apple.com/). 

There are indications that accounts newly registered through [Apple Music](https://play.google.com/store/apps/details?id=com.apple.android.music) do not have this issue.

Unfortunately, there is no general solution as Apple changes the mechanism. After the data has been added, the registration can be restarted:

```
docker stop macless-haystack
docker start -ai macless-haystack
```

#### How can I secure the endpoint?

The endpoint can and should be secured, especially if it is exposed to the internet. This authentication can be configured in the config.ini file (using the keys `endpoint_user` and `endpoint_pass`). After restarting the container, the log output should indicate a successful authentication.

The data must, of course, also be entered into the configuration of the frontend.

#### How can I host my own web-frontend?

You shouldn't do that because there's no reason for it. It's better to use the web frontend on [Github](https://dchristl.github.io/macless-haystack/). 
The frontend is always up to date and runs stable. Security concerns regarding data are also not an issue here because GitHub only delivers the empty page. All data such as location, keys, request frequency, etc., are not transmitted to GitHub. All communication then occurs only between your system (browser) and the endpoint. Theoretically, after the page has been loaded, GitHub could be blocked in the firewall, and the application would still work.

The frontend is still offered for download in the releases (webapplication.zip) and can be self-hosted.

#### How do I update the Docker container

An update of the container should generally not be necessary, as it automatically updates when restarted. This can be achieved by using 
```
docker restart macless-haystack
```

Upon startup, the container automatically fetches the latest state from this repository. If, however, an update of the container is necessary (for example, if it is mentioned in the release notes), the old one can be deleted and a new one pulled with:

```
docker rm -f macless-haystack
docker rmi christld/macless-haystack
docker run -d --restart unless-stopped --name macless-haystack -p 6176:6176 --volume mh_data:/app/endpoint/data --network mh-network christld/macless-haystack
```
A new registration is usually not necessary, as the data is retained.

#### Restart the registration/change account

If, for example, your activation was successful, and you still don't have access or simply want to switch your account, you can repeat the registration by deleting the auth.json and restarting the container:

```
docker stop macless-haystack
sudo rm /var/lib/docker/volumes/mh_data/_data/auth.json #adjust folder, if needed
docker start macless-haystack
```

#### How can I reset everything and start over7 How can i completely uninstall Macless Haystack


You can start completely from scratch by deleting the container and the data. After that, you can begin the guide from the beginning:

```
docker rm -f macless-haystack
docker rmi christld/macless-haystack
docker volume rm mh_data
docker rm -f anisette
docker rmi dadoum/anisette-v3-server
docker volume rm anisette-v3_data
docker volume prune
docker network rm mh-network
docker network prune
```

#### How can I access a running container with a shell

You can always access the shell of the container with:
```
docker exec -it  macless-haystack /bin/bash -c "export TERM=xterm; exec bash"
```
#### How can I use SSL if the endpoint runs on another machine than the UI?

If you want to use Macless Haystack not on the same machine your browser is running or you want to use SSL, some extra steps are needed. You need a valid certificate, called certificate.pem in the server's folder or you can rename the file rename_me.pem as root to certificate.pem and use my self signed one. After that restart the container: 
```
sudo su
cd /var/lib/docker/volumes/mh_data/_data
mv rename_me.pem certificate.pem
docker restart macless-haystack
```
If you used a self signed certificate go to your client where you want to run Macless Haystack and point your browser to your endpoint (i.e. https://myserver:6176). You should see something like that:
![Certificate error](firefox_cert.png)

Go to 'Advanced' and 'Accept the Risk and continue'. You should see a directory listing now. Use Macless Haystack now normally, but change the endpoint server setting, according to your needs. Use now https instead!

#### How can I use my own certificate with private and public key (i.e. [Let's Encrypt](https://letsencrypt.org/) ) 

The certificate is created according to the current instructions from Let's Encrypt and then symbolically linked in the container. If there is a file alongside certificate.pem (public key) called privkey.pem (private key), they will be used. The two files will be linked like that (Check out the folder and file-names)

```
sudo ln -s <path_to_private_key> /var/lib/docker/volumes/mh_data/_data/privkey.pem 
sudo ln -s <path_to_public_key> /var/lib/docker/volumes/mh_data/_data/certificate.pem
```
