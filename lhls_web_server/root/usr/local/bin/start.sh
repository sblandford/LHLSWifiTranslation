#!/bin/ash
if [ -e /var/www/html/lhls/audio/data ]; then
    echo "Setting ownership of /var/www/html/lhls/audio/data"
    chown apache:www-data /var/www/html/lhls/audio/data
else
    echo "Not found : /var/www/html/lhls/audio/data"
fi
/usr/sbin/httpd -DFOREGROUND
