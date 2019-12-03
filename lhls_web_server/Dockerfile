FROM alpine:latest

MAINTAINER Simon Blandord <simon@bkconnect.net>

COPY root/. /

RUN apk update && apk upgrade && \
    # Install Apache
    apk add apache2 libxml2-dev apache2-utils php7 php7-apache2 php7-session php7-json && \
    chmod +x /usr/local/bin/start.sh && \
    mkdir -p /var/www/html/lhls/audio && \
    chmod 777 /var/www/html/lhls/audio && \
    mkdir -p /var/www/cgibin && chown -R apache.www-data /var/www && \
    sed -i 's#^DocumentRoot ".*#DocumentRoot "/var/www/html"#g' /etc/apache2/httpd.conf && \
    sed -i 's#AllowOverride [Nn]one#AllowOverride All#' /etc/apache2/httpd.conf && \
    sed -i 's/^#ServerName.*/ServerName LHLS/' /etc/apache2/httpd.conf && \
    sed -i 's#Directory "/var/www/localhost/htdocs.*#Directory "/var/www/html" >#g' /etc/apache2/httpd.conf && \
    sed -i 's#Directory "/var/www/localhost/cgi-bin.*#Directory "/var/www/cgi-bin" >#g' /etc/apache2/httpd.conf && \
    sed -i 's#^ErrorLog.*#ErrorLog /dev/stderr#g' /etc/apache2/httpd.conf && \
    sed -i 's#CustomLog logs/access.log#CustomLog "|/usr/sbin/rotatelogs -t -c /var/www/html/access.log 1M"#g' /etc/apache2/httpd.conf && \
    sed -i 's/#LoadModule rewrite_module/LoadModule rewrite_module/g' /etc/apache2/httpd.conf && \
    sed -i 's/#LoadModule expires_module/LoadModule expires_module/g' /etc/apache2/httpd.conf && \
    sed -i 's/MaxKeepAliveRequests.*/MaxKeepAliveRequests 10000/g' /etc/apache2/conf.d/default.conf && \
    sed -i 's#apache:/var/www:/sbin/nologin#apache:/var/www:/bin/ash#g' /etc/passwd && \
    # remove cached info
    rm -rf /var/cache/apk/*

# Set environment variables.
ENV HOME /var/www/html

# Web server port
EXPOSE 80/tcp

# Define default command.
CMD ["/usr/local/bin/start.sh"]
