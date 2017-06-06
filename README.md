## This image has been deprecated. Please use the new image here: https://hub.docker.com/r/linuxserver/letsencrypt/
It is based on alpine, leaner, meaner and more up to date

### Nginx-Letsencrypt

This container sets up an Nginx webserver with a built-in letsencrypt client that automates free SSL server certificate generation and renewal processes.

#### Install On unRaid:

On unRaid, install from the Community Applications and enter the app folder location, server ports and the email, the domain url and the subdomains (comma separated, no spaces) under advanced view. Note: 
- Make sure that the port 443 in the container is accessible from the outside of your lan. It is OK to map container's port 443 to another port on the host (ie 943) as long as your router will forward port 443 from the outside to port 943 on the host and it will end up at port 443 in the container. If this is confusing, just leave 443 mapped to 443 and forward port 443 on your router to your unraid IP.
- Prior to SSL certificate creation, letsencrypt creates a temporary webserver and checks to see if it is accessible through the domain url provided for validation. Make sure that your server is reachable through your.domain.url:443 and that port 443 is forwarded on your router to the container's port 443 prior to running this docker. Otherwise letsencrypt validation will fail, and no certificates will be generated.
- If you prefer your dhparams to be 4096 bits (default is 2048), add an environment variable under advanced view `DHLEVEL` that equals `4096`
- If you prefer to get a certificate only for subdomains and not the url (for instance a cert that covers mail.url.com and ftp.url.com but not url.com), add an environment variable under advanced view `ONLY_SUBDOMAINS` that equals `true`


#### Install On Other Platforms (like Ubuntu or Synology 5.2 DSM, etc.):

On other platforms, you can run this docker with the following command:

```
docker run -d \
  --privileged \
  --name="Nginx-letsencrypt" \
  -p 80:80 \
  -p 443:443 \
  -e EMAIL="youremail" \
  -e URL="yourdomain.url" \
  -e SUBDOMAINS="www,subdomain1,subdomain2"  \
  -e TZ="America/New_York" \
  -v /path/to/config/:/config:rw \
  aptalca/nginx-letsencrypt
```

- Replace the EMAIL variable (youremail) with the e-mail address you would like to register the SSL certificate with.
- Replace the URL variable (yourdomain.url) with your server's internet domain name, without any subdomains (can also be a dynamic dns url, ie. google.com or username.duckdns.org).
- Replace the SUBDOMAINS variable with your choice of subdomains (just the subdomains, comma separated, no spaces).
- Replace "America/New_York" with your timezone if different. List of timezones available here: http://php.net/manual/en/timezones.php
- Replace the "/path/to/config" with your choice of location.
- Make sure that the port 443 in the container is accessible from the outside of your lan. It is OK to map container's port 443 to another port on the host (ie 943) as long as your router will forward port 443 from the outside to port 943 on the host and it will end up at port 443 in the container. If this is confusing, just leave the `-p 443:443` portion of the run command as is and forward port 443 on your router to your host IP.
- Prior to SSL certificate creation, letsencrypt creates a temporary webserver and checks to see if it is accessible through the domain url provided for validation. Make sure that your server is reachable through your.domain.url:443 and that port 443 is forwarded on your router to the container's port 443 prior to running this docker. Otherwise letsencrypt validation will fail, and no certificates will be generated.
- Fail2ban is extremely useful for preventing DDOS attacks or brute force methods that attempt to thwart htpasswd security. Default implementation includes blocking unsuccessful attempts at htpasswd based authentication. You can add more filters by modifying the `/config/nginx/jail.local` file and dropping the filter files in the `/config/nginx/fail2ban-filters` folder. Don't forget to restart the container afterwards.
- OPTIONAL: If you prefer your dhparams to be 4096 bits (default is 2048), add the following to your run command: `-e DHLEVEL="4096"`
- NOTE: PHP is finally fixed. Switched to using `unix:/var/run/php5-fpm.sock`. If you're updating an existing install (from prior to the 2016-04-12 build), delete your nginx-fpm.conf file, modify your default site config to utilize `unix:/var/run/php5-fpm.sock` instead of `127.0.0.1:9000` (as in here: https://github.com/aptalca/docker-webserver/blob/master/defaults/default ) and restart the container
- OPTIONAL: If you'd like to generate a cert only for subdomains and not for the url (for instance a cert that covers mail.url.com and ftp.url.com but not url.com), include the following parameter in your run command: `-e ONLY_SUBDOMAINS="true"`
- NOTE: This container recognizes any changes to the parameters entered. If there are changes to the url or domains, it will attempt to revoke the existing certs and generate new ones. Keep in mind that if you change them too many times, letsencrypt will throttle requests and you may be denied new certs for a period of time. Check the logs for suspected throttling.
- NOTE: New version automatically creates a pfx key file with every renewal, which you can use for applications such as Emby

  
You can access your webserver at `https://subdomain.yourdomain.url/`  
  
#### Changelog: 
- 2016-09-22 - Fixed deletion of symlink after failed install
- 2016-08-19 - Added ability to generate certs ONLY for subdomains, without the url (many thanks to @stuwil for PR) - Greatly simplified the cert renewal process - Updated php - Added auto generated pfx private key - Added ability to change DH bit parameter without having to delete the existing file
- 2016-06-18 - Log rotation fixed - Letsencrypt log moved to its own folder - Fixed missing e-mail paramater when renewing through cron
- 2016-06-03 - Added ability to change url and subdomains (container will automatically recognize changes to the variables upon start, and will update the cert accordingly) - Updated nginx to 1.10.1 - Switched to using certbot, the new official letsencrypt client maintained by EFF
- 2016-05-06 - Updated nginx to 1.10.0 - Updated phusion baseimage to 18
- 2016-04-16 - Fixed bug with detecting fail2ban.sock, which prevented fail2ban start
- 2016-04-12 - Many changes under the hood to streamline - new/renewed certs will be 4096 bits - added option for 4096 bit dhparams - no more git, only uses the single letsencrypt-auto script - all environment variables match (bash, init and cron) - fixed bug affecting multiple subdomains - finally fixed php (may have to change your site config to use "fastcgi_pass unix:/var/run/php5-fpm.sock;" as in here: https://github.com/aptalca/docker-webserver/blob/master/defaults/default ) and delete your nginx-fpm.conf file and restart
- 2016-04-11 - Fixed the cron environment issue that could break script updates
- 2016-04-08 - Fixed update bug (accidentally removed a line in previous update)
- 2016-04-07 - Remove the git pull as the April 6th update of the auto script to ver 0.5.0 no longer needs it
- 2016-04-05 - Add nightly git pull to prevent letsencrypt update errors
- 2016-03-29 - Quick fix for nginx not starting
- 2016-03-29 - IMPORTANT UPDATE, cron script has been fixed (wasn't getting the correct env variables), letsencrypt updates more frequently (infrequent updates could error and break cert updates), cron now runs everynight at midnight to check status and updates letsencrypt, letsencrypt log file gets appended with cron output for tracking update history
- 2016-03-08 - Fixed issue with fail2ban not starting following container crash
- 2016-01-15 - Added fail2ban support (Important: If updating from earlier, notice that a `--privileged` flag is added to the run command. Without it, fail2ban does not work due to inability to modify iptables)
- 2016-01-05 - Fixed permissions for php-fpm and memcached (they were not starting) - Fixed silly typo causing cert renewal every 6 days instead of 60
- 2016-01-03 - Updated to support multiple subdomains
- 2015-12-29 - Initial Release
