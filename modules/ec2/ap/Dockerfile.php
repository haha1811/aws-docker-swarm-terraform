FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y apache2 libapache2-mod-php7.4 php7.4-mysql vim net-tools iputils-ping mysql-client

# 改 Apache 為監聽 8080
RUN echo "Listen 8080" > /etc/apache2/ports.conf && \
    sed -i 's/<VirtualHost \*:80>/<VirtualHost *:8080>/g' /etc/apache2/sites-available/000-default.conf

# 複製網站程式
COPY index.php /var/www/html/
COPY register.php /var/www/html/

WORKDIR /var/www/html/

EXPOSE 8080

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
