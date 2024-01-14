### Notes on usage on other machines (SSL)

> 
> If you want to use Macless Haystack not on the same machine your browser is running or you want to use SSL, some extra steps are needed. You need a valid certificate, called certificate.pem in the server's folder (i.e. created with [Let's Encrypt](https://letsencrypt.org/) ) or you can rename the file rename_me.pem as root to certificate.pem and use my self signed one. After that restart the container: 
```
sudo su
cd /var/lib/docker/volumes/mh_data/_data
mv rename_me.pem certificate.pem
docker restart macless-haystack

```
If you used a self signed certificate go to your client where you want to run Macless Haystack and point your browser to your endpoint (i.e. https://myserver:6176). You should see something like that:
![Certificate error](firefox_cert.png)

Go to 'Advanced' and 'Accept the Risk and continue'. You should see a directory listing now. Use Macless Haystack now normally, but change the endpoint server setting, according to your needs. Use now https instead!