
## Frequently asked questions

**Where and what data is stored on the host?**

During the installation, a Docker volume (*mh_data*) is created, which is located in the default folder. This is normally under `/var/lib/docker/volumes/mh_data/_data`, but you can check, if your location is different, with:

```
docker inspect macless-haystack | grep mh_data
```
Check out the *Source*-key. The folder is typically protected and can only be accessed and modified by the root user.

In the folder you'll find the configuration (config.ini), the authentication (auth.json), if it has already been executed. Additionally, the self-signed certificate used for SSL is also located here.

**What is the config.ini used for?**

This is where specific settings can be configured, for example, if another/existing Anisette server is to be used or if you want to provide a username and password. Normally, no adjustments should be necessary here.

**How do I update the Docker container**

An update of the container should generally not be necessary, as it automatically updates when restarted. This can be achieved by using 
```
docker restart macless-haystack
```

Upon startup, the container automatically fetches the latest state from this repository. If, however, an update of the container is necessary (for example, if it is mentioned in the release notes), the old one can be deleted and a new one pulled with:

```
docker rm -f macless-haystack
docker rmi macless-haystack
docker run -d --restart unless-stopped --name macless-haystack -p 6176:6176 --volume mh_data:/app/endpoint/data --network mh-network christld/macless-haystackdocker run -it --restart unless-stopped --name macless-haystack -p 6176:6176 --volume mh_data:/app/endpoint/data --network mh-network christld/macless-haystack
```
A new registration is usually not necessary, as the data is retained.

**Restart the registration/change account**


If, for example, your activation was successful, and you still don't have access or simply want to switch your account, you can repeat the registration by deleting the auth.json and restarting the container:

```
docker stop macless-haystack
sudo rm /var/lib/docker/volumes/mh_data/_data/auth.json #adjust folder, if needed
docker start macless-haystack
```

**How can I reset everything and start over7 How can i completely uninstall Macless Haystack**


You can start completely from scratch by deleting the container and the data. After that, you can begin the guide from the beginning:

```
docker rm -f macless-haystack
docker rmi macless-haystack
docker volume rm mh_data
docker rm -f anisette
docker rmi anisette
docker volume rm anisette-v3_data
docker volume prune
docker network rm mh-network
docker network prune
```

**How can I access a running container with a shell**

You can always access the shell of the container with:
```
docker exec -it  macless-haystack /bin/bash -c "export TERM=xterm; exec bash"
```

**How can I use SSL if the endpoint runs on another machine than the UI?**

If you want to use Macless Haystack not on the same machine your browser is running or you want to use SSL, some extra steps are needed. You need a valid certificate, called certificate.pem in the server's folder (i.e. created with [Let's Encrypt](https://letsencrypt.org/) ) or you can rename the file rename_me.pem as root to certificate.pem and use my self signed one. After that restart the container: 
```
sudo su
cd /var/lib/docker/volumes/mh_data/_data
mv rename_me.pem certificate.pem
docker restart macless-haystack
```
If you used a self signed certificate go to your client where you want to run Macless Haystack and point your browser to your endpoint (i.e. https://myserver:6176). You should see something like that:
![Certificate error](firefox_cert.png)

Go to 'Advanced' and 'Accept the Risk and continue'. You should see a directory listing now. Use Macless Haystack now normally, but change the endpoint server setting, according to your needs. Use now https instead!