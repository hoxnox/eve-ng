#!/bin/sh

# create unetlab symlink for script compatibility
ln -s /usr/src/eve-ng-public /usr/src/unetlab
./syncunl
# install guacamole
./guac_install_v1.5.sh
# creata unetlab DB
apt-get install sqlite3
mysql -u root --password=eve-ng mysql < unetlab.sql

#insert original users
echo ".dump users " | sqlite3 /opt/unetlab/data/database.sdb | grep -i insert | sed -e 's/);/,1);/' -e 's/"/`/g'  |  mysql -u eve-ng --password=eve-ng eve_ng_db

# enable proxy mod apache
a2enmod proxy_html
a2enmod proxy_http
a2enmod proxy_wstunnel

# add php mysql module

apt-get install php5-mysql

# add directive to apache for proxy

cp proxy.conf /etc/apache2/mods-enabled/proxy.conf 

# Restart apache

/etc/init.d/apache2 restart
/etc/init.d/tomcat7 restart
/etc/init.d/guacd restart
