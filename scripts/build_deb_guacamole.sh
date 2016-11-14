#!/bin/bash
BUILD_DIR="/build"
LOG="/tmp/eve_build.log"
SRC_DIR="/usr/src/eve-ng-public-dev"
DISTNAME=$(lsb_release -c -s)
CONTROL="${SRC_DIR}/debian/guacamole_${DISTNAME}_control.template"
CONTROL_DIR="$(mktemp -dt eve_control.XXXXXXXXXX)"
DATA_DIR="$(mktemp -dt eve_data.XXXXXXXXXX)"
TMP="$(mktemp -dt eve_tmp.XXXXXXXXXX)"
DEBIAN_FRONTEND="noninteractive"

FAILED="\033[0;31mfailed\033[0m"
WARNING="\033[1;33mwarning\033[0m"
INFO="\033[0;34mblue\033[0m"
DONE="\033[0;32mdone\033[0m"

GUAC_VER="0.9.9"
MYSQL_CONNECTOR_VERSION="5.1.38"
MYSQL_ROOT_PASSWD="eve-ng"
GUAC_DB_PASSWD="eve-ng"
GUAC_ADMIN_PASSWORD="eve-ng"

#Get dev package
apt-get install libcairo2-dev libfreerdp-dev libjpeg-turbo8-dev libossp-uuid-dev libpango1.0-dev libpng12-dev libpulse-dev libssh2-1-dev libssl-dev libtelnet-dev libvncserver-dev libvorbis-dev
# Downloading Guacamole
echo -ne "Downloading Guacamole ${GUAC_VER}... "

cd /usr/src
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi
wget -q -O guacamole-server-$GUAC_VER.tar.gz http://sourceforge.net/projects/guacamole/files/current/source/guacamole-server-$GUAC_VER.tar.gz &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi
tar -zxf guacamole-server-$GUAC_VER.tar.gz &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi
wget -q -O guacamole-$GUAC_VER.war http://sourceforge.net/projects/guacamole/files/current/binary/guacamole-$GUAC_VER.war &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi
wget -q -O guacamole-auth-jdbc-$GUAC_VER.tar.gz http://sourceforge.net/projects/guacamole/files/current/extensions/guacamole-auth-jdbc-$GUAC_VER.tar.gz &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi
tar -zxf guacamole-auth-jdbc-$GUAC_VER.tar.gz &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi
wget -q -O mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.tar.gz http://dev.mysql.com/get/Downloads/Connector/j/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.tar.gz &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi
tar -zxf mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.tar.gz &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

echo -e ${DONE}

# Installing dependencies
#echo -ne "Installing dependencies... "

#PACKAGES="$(cat ${CONTROL} 2>> ${LOG} | grep "Depends" 2>> ${LOG} | sed 's/Depends: //' 2>> ${LOG} | sed 's/,//g' 2>> ${LOG} | sed 's/ (.*)//g' 2>> ${LOG})"
#apt-get -qqy install ${PACKAGES} &>> ${LOG}
#if [ $? -ne 0 ]; then
#	echo -e ${FAILED}
#	exit 1
#fi

#echo -e ${DONE}

# Environment for both Ubuntu 14.04 and 16.04
echo -ne "Building environment... "

VERSION="$(cat ${SRC_DIR}/VERSION 2>> ${LOG} | cut -d- -f1 2>> ${LOG})"
RELEASE="$(cat ${SRC_DIR}/VERSION 2>> ${LOG} | cut -d- -f2 2>> ${LOG})"

mkdir -p ${BUILD_DIR} ${CONTROL_DIR} ${DATA_DIR}/usr/local /build/apt/pool/${DISTNAME}/e/eve-ng-guacamole
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

# Environment for Ubuntu 14.04
cat ${CONTROL} 2>> ${LOG} | sed "s/%VERSION%/${VERSION}/" 2>> ${LOG} | sed "s/%RELEASE%/${RELEASE}/" 2>> ${LOG} > ${CONTROL_DIR}/control
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

echo -e ${DONE}

echo -ne "Calculating installed size... "
SIZE=$(du -sk ${DATA_DIR} | awk '{print $1}')
sed -i "s/^Installed-Size.*/Installed-Size: ${SIZE}/g" ${CONTROL}
if [ $? -ne 0 ]; then
    echo -e ${FAILED}
    exit 1
fi
echo -e ${DONE}

# Building deb packages
echo -ne "Building deb packages... "

cd /usr/src/guacamole-server-$GUAC_VER/
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cat > ${CONTROL_DIR}/preinst << EOF
#!/bin/bash

echo -ne "Checking MySQL... "
echo "\q" | mysql -u root --password=${MYSQL_ROOT_PASSWD} &> /dev/null
if [ \$? -ne 0 ]; then
	echo -e "${FAILED}"
	exit 1
fi

echo -e "${DONE}"

echo "\q" | mysql -u root --password=${MYSQL_ROOT_PASSWD} guacdb &> /dev/null
if [ \$? -ne 0 ]; then
	echo -ne "Creating database and users... "
	echo "CREATE DATABASE IF NOT EXISTS guacdb;" | mysql --host=localhost --user=root --password=${MYSQL_ROOT_PASSWD} &> /dev/null
	if [ \$? -ne 0 ]; then
		echo -e "${FAILED}"
		exit 1
	fi
	echo "GRANT ALL ON guacdb.* TO 'guacuser'@'localhost' IDENTIFIED BY '${GUAC_DB_PASSWD}';" | mysql --host=localhost --user=root --password=${MYSQL_ROOT_PASSWD} &> /dev/null
	if [ \$? -ne 0 ]; then
		echo -e "${FAILED}"
		exit 1
	fi
	cat /opt/unetlab/schema/guacamole-*.sql | mysql --host=localhost --user=root --password=${MYSQL_ROOT_PASSWD} guacdb &> /dev/null
	if [ \$? -ne 0 ]; then
		echo -e "${FAILED}"
		exit 1
	fi
	echo "SET @salt = UNHEX(SHA2(UUID(), 256)); UPDATE guacamole_user SET password_salt = @salt, password_hash = UNHEX(SHA2(CONCAT('${GUAC_ADMIN_PASSWORD}', HEX(@salt)), 256)) WHERE username = 'guacadmin';" | mysql --user=root --password=${MYSQL_ROOT_PASSWD} guacdb &> /dev/null
	if [ \$? -ne 0 ]; then
		echo -e "${FAILED}"
		exit 1
	fi

	echo -e "${DONE}"
fi
EOF

if [ "${DISTNAME}" == "trusty" ] ; then
	cat > ${CONTROL_DIR}/postinst << EOF
#!/bin/bash
ldconfig -v &> /dev/null
echo -ne "Enable services at boot... "
update-rc.d tomcat7 enable &> /dev/null
update-rc.d mysql enable &> /dev/null
update-rc.d guacd enable &> /dev/null
echo -e "${DONE}"
echo -ne "Starting Tomcat... "
cp -a /etc/tomcat7/server-guacamole.xml /etc/tomcat7/server.xml &> /dev/null 
service tomcat7 restart &> /dev/null
pgrep -u tomcat7 java &> /dev/null && echo -e "${DONE}" || echo -e "${FAILED}"
echo -ne "Starting Guacamole daemon... "
service guacd restart &> /dev/null
pgrep guacd &> /dev/null && echo -e "${DONE}" || echo -e "${FAILED}"
EOF
	if [ $? -ne 0 ]; then
		echo -e ${FAILED}
		exit 1
	fi
TOMCAT_VER="7"
fi

if [ "${DISTNAME}" == "xenial" ] ; then
cat > ${CONTROL_DIR}/postinst << EOF
#!/bin/bash
echo -ne "Enable services at boot... "
systemctl enable tomcat8 &> /dev/null
systemctl enable mysql &> /dev/null
systemctl enable guacd &> /dev/null
echo -e "${DONE}"
echo -ne "Starting Tomcat... "
cp -a /etc/tomcat8/server-guacamole.xml /etc/tomcat8/server.xml &> /dev/null
sed -i -e'/.*Jasper.*/d' /etc/tomcat8/server.xml &> /dev/null
systemctl restart tomcat8 &> /dev/null
pgrep -u tomcat8 java &> /dev/null && echo -e "${DONE}" || echo -e "${FAILED}"
ldconfig -vv &> /dev/null
systemctl restart guacd &> /dev/null
pgrep guacd &> /dev/null && echo -e "${DONE}" || echo -e "${FAILED}"
EOF
	if [ $? -ne 0 ]; then
		echo -e ${FAILED}
		exit 1
	fi
TOMCAT_VER="8"
fi


DEBFILE="/build/apt/pool/${DISTNAME}/e/eve-ng-guacamole/eve-ng-guacamole_${VERSION}-${RELEASE}_amd64.deb"

cd /usr/src/guacamole-server-$GUAC_VER/
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi
make clean &>> ${LOG}
./configure --prefix=${DATA_DIR}/usr/local &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi
make &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi
make install &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

mkdir -p ${DATA_DIR}/usr/share/tomcat${TOMCAT_VER}/.guacamole/extensions ${DATA_DIR}/usr/share/tomcat${TOMCAT_VER}/.guacamole/lib ${DATA_DIR}/var/lib/tomcat${TOMCAT_VER}/webapps ${DATA_DIR}/usr/share/tomcat${TOMCAT_VER}/.guacamole/{extensions,lib} ${DATA_DIR}/etc/tomcat${TOMCAT_VER}  ${DATA_DIR}/etc/init.d &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi
cp -a /usr/src/guacamole-${GUAC_VER}.war ${DATA_DIR}/var/lib/tomcat${TOMCAT_VER}/webapps/guacamole.war &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi
cp -a /usr/src/guacamole-auth-jdbc-${GUAC_VER}/mysql/guacamole-auth-jdbc-mysql-${GUAC_VER}.jar ${DATA_DIR}/usr/share/tomcat${TOMCAT_VER}/.guacamole/extensions &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi
cp -a /usr/src/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}-bin.jar ${DATA_DIR}/usr/share/tomcat${TOMCAT_VER}/.guacamole/lib/ &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi
cp -a /usr/src/guacamole-auth-jdbc-${GUAC_VER}/mysql/guacamole-auth-jdbc-mysql-${GUAC_VER}.jar ${DATA_DIR}/usr/share/tomcat${TOMCAT_VER}/.guacamole/extensions/ &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi
cp -a ${SRC_DIR}/etc/guacamole.properties ${DATA_DIR}/usr/share/tomcat${TOMCAT_VER}/.guacamole/ &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi
cp -a ${SRC_DIR}/etc/server.xml ${DATA_DIR}/etc/tomcat${TOMCAT_VER}/server-guacamole.xml &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi
cp -a ${SRC_DIR}/etc/guacd ${DATA_DIR}/etc/init.d/ &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cd ${DATA_DIR} &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

tar czf data.tar.gz * &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

find -type f -exec md5sum {} \; >> ${CONTROL_DIR}/md5sums 2>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

echo 2.0 > ${CONTROL_DIR}/debian-binary 2>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cd ${CONTROL_DIR} &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

tar czf control.tar.gz md5sums control postinst preinst &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cd ${SRC_DIR}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

ar -cr ${DEBFILE} ${CONTROL_DIR}/debian-binary ${CONTROL_DIR}/control.tar.gz ${DATA_DIR}/data.tar.gz &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

echo -e ${DONE}

rm -rf ${CONTROL_DIR} ${DATA_DIR} ${LOG}

# Build completed
echo -e "Build completed:"
ls -l /build/apt/pool/*/e/eve-ng-guacamole/eve-ng-guacamole_*.deb

