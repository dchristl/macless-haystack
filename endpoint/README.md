### Notes on usage on other machines (SSL)

> 
> If you want to use Headless Haystack not on the same machine your browser is running or you want to use SSL, some extra steps are needed. You need a valid certificate, called certificate.pem in the server's folder (i.e. created with [Let's Encrypt](https://letsencrypt.org/) ) or you can rename the file rename_me.pem to certificate.pem and use my self signed one. After that restart the service: 
```
mv rename_me.pem certificate.pem
./FindMy_proxy.py
```
Go to your client where you want to run Headless Haystack and point your browser to your FindMyProxy-Server (i.e. https://myserver:56176). You should see something like that:
![Certificate error](firefox_cert.png)

Go to 'Advanced' and 'Accept the Risk and continue'. You should see a directory listing now. Use Headless Haystack now normally, but change the fetch location server setting, according to your needs. Use now https instead!