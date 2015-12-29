### Nginx-Letsencrypt

This container sets up an Nginx webserver with a built-in letsencrypt client that automates free SSL server certificate generation and renewal processes.

#### Install On unRaid:

On unRaid, install from the Community Applications and enter the app folder location, server ports and the email and the domain url under advanced view. Note: Make sure that the port 443 in the container is accessible from the outside of your lan. It is OK to map container's port 443 to another port on the host (ie 943) as long as your router will forward port 443 from the outside to port 943 on the host and it will end up at port 443 in the container. If this is confusing, just leave 443 mapped to 443 and forward port 443 on your router to your unraid IP.


#### Install On Other Platforms (like Ubuntu or Synology 5.2 DSM, etc.):

On other platforms, you can run this docker with the following command:

```docker run -d --name="Nginx-letsencrypt" -p 80:80 -p 443:443 -e EMAIL="youremail" -e URL="your.domain.url" -v /path/to/config/:/config:rw -v /etc/localtime:/etc/localtime:ro aptalca/nginx-letsencrypt```

- Replace the EMAIL variable (youremail) with the e-mail address you would like to register the SSL certificate with.
- Replace the URL variable (your.domain.url) with your server's internet domain name (can also be a dynamic dns url).
- Replace the "/path/to/config" with your choice of location.
- Make sure that the port 443 in the container is accessible from the outside of your lan. It is OK to map container's port 443 to another port on the host (ie 943) as long as your router will forward port 443 from the outside to port 943 on the host and it will end up at port 443 in the container. If this is confusing, just leave the `-p 443:443` portion of the run command as is and forward port 443 on your router to your host IP.
- Prior to SSL certificate creation, letsencrypt creates a temporary webserver and check to see if it is accessible through the domain provided for validation. Make sure that your server is reachable through your.domain.url:443 and that port 443 is forwarded on your router to the container's port 443 prior to running this docker. Otherwise letsencrypt validation will fail, and no certificates will be generated.

  
You can access your webserver at `https://your.domain.url/`  
  
#### Changelog: 
- 2015-12-29 - Initial Release
