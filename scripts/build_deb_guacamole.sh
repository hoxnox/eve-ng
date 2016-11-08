#!/bin/bash
BUILD_DIR="/build"
LOG="/tmp/eve_build.log"
SRC_DIR="/usr/src/eve-ng-public-dev"
CONTROL="${SRC_DIR}/debian/guacamole_control.template"
CONTROL_DIR_14="$(mktemp -dt eve_control_14.XXXXXXXXXX)"
DATA_DIR_14="$(mktemp -dt eve_data_14.XXXXXXXXXX)"
CONTROL_DIR_16="$(mktemp -dt eve_control_16.XXXXXXXXXX)"
DATA_DIR_16="$(mktemp -dt eve_data_16.XXXXXXXXXX)"
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
echo -ne "Installing dependencies... "

PACKAGES="$(cat ${CONTROL} 2>> ${LOG} | grep "Depends" 2>> ${LOG} | sed 's/Depends: //' 2>> ${LOG} | sed 's/,//g' 2>> ${LOG} | sed 's/ (.*)//g' 2>> ${LOG})"
apt-get -qqy install ${PACKAGES} &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

echo -e ${DONE}

# Environment for both Ubuntu 14.04 and 16.04
echo -ne "Building environment... "

VERSION="$(cat ${SRC_DIR}/VERSION 2>> ${LOG} | cut -d- -f1 2>> ${LOG})"
RELEASE="$(cat ${SRC_DIR}/VERSION 2>> ${LOG} | cut -d- -f2 2>> ${LOG})"

mkdir -p ${BUILD_DIR} {${CONTROL_DIR_14},${CONTROL_DIR_16}} {${DATA_DIR_14},${DATA_DIR_16}}/usr/local /build/apt/pool/{trusty,xenial}/e/eve-ng-guacamole
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

# Environment for Ubuntu 14.04
cat ${CONTROL} 2>> ${LOG} | sed "s/%VERSION%/${VERSION}/" 2>> ${LOG} | sed "s/%RELEASE%/${RELEASE}/" 2>> ${LOG} > ${CONTROL_DIR_14}/control
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

# Environment for Ubuntu 16.04
cat ${CONTROL} 2>> ${LOG} | sed "s/%VERSION%/${VERSION}/" 2>> ${LOG} | sed "s/%RELEASE%/${RELEASE}/" 2>> ${LOG} | sed "s/tomcat7/tomcat8/g" 2>> ${LOG} > ${CONTROL_DIR_16}/control
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

cat > ${CONTROL_DIR_14}/preinst << EOF
#!/bin/bash

dpkg -l mysql-server &> /dev/null
if [ \$? -ne 0 ]; then
	echo -ne "Installing MySQL... "

	echo mysql-server mysql-server/root_password password "${MYSQL_ROOT_PASSWD}" 2> /dev/null | debconf-set-selections &> /dev/null
	if [ \$? -ne 0 ]; then
		echo -e "${FAILED}"
		exit 1
	fi

	echo mysql-server mysql-server/root_password_again password "${MYSQL_ROOT_PASSWD}" 2> /dev/null | debconf-set-selections &> /dev/null
	if [ \$? -ne 0 ]; then
		echo -e "${FAILED}"
		exit 1
	fi

	apt-get -qqy install mysql-server &> /dev/null
	if [ \$? -ne 0 ]; then
		echo -e "${FAILED}"
		exit 1
	fi

	echo -e "${DONE}"
fi

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

cp -a ${CONTROL_DIR_14}/preinst ${CONTROL_DIR_16}/preinst &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cat > ${CONTROL_DIR_14}/postinst << EOF
#!/bin/bash
echo -ne "Enable services at boot... "
update-rc.d tomcat7 enable &> /dev/null
update-rc.d mysql enable &> /dev/null
echo -e "${DONE}"
echo -ne "Starting Tomcat... "
cp -a /etc/tomcat7/server-guacamole.xml /etc/tomcat7/server.xml &> /dev/null
service tomcat7 restart &> /dev/null
pgrep -u tomcat7 java &> /dev/null && echo -e "${DONE}" || echo -e "${FAILED}"
EOF
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cat > ${CONTROL_DIR_16}/postinst << EOF
#!/bin/bash
echo -ne "Enable services at boot... "
systemctl enable tomcat8 &> /dev/null
systemctl enable mysql &> /dev/null
echo -e "${DONE}"
echo -ne "Starting Tomcat... "
cp -a /etc/tomcat8/server-guacamole.xml /etc/tomcat8/server.xml &> /dev/null
systemctl restart tomcat7 &> /dev/null
pgrep -u tomcat7 java &> /dev/null && echo -e "${DONE}" || echo -e "${FAILED}"
EOF
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

for i in 14 16; do
	if [ ${i} -eq 14 ]; then
		DEBFILE="/build/apt/pool/trusty/e/eve-ng-guacamole/eve-ng-guacamole_${VERSION}-${RELEASE}_amd64.deb"
		TOMCAT_VER="7"
	else
		DEBFILE="/build/apt/pool/xenial/e/eve-ng-guacamole/eve-ng-guacamole_${VERSION}-${RELEASE}_amd64.deb"
		TOMCAT_VER="8"
	fi

	cd /usr/src/guacamole-server-$GUAC_VER/
	if [ $? -ne 0 ]; then
		echo -e ${FAILED}
		exit 1
	fi
	make clean &>> ${LOG}
	./configure --prefix=$(eval 'echo ${'"DATA_DIR_$i"'}/usr/local') &>> ${LOG}
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

	mkdir -p $(eval 'echo ${'"DATA_DIR_$i"'}')/usr/share/tomcat${TOMCAT_VER}/.guacamole/extensions $(eval 'echo ${'"DATA_DIR_$i"'}')/usr/share/tomcat${TOMCAT_VER}/.guacamole/lib $(eval 'echo ${'"DATA_DIR_$i"'}')/var/lib/tomcat${TOMCAT_VER}/webapps $(eval 'echo ${'"DATA_DIR_$i"'}')/usr/share/tomcat${TOMCAT_VER}/.guacamole/{extensions,lib} $(eval 'echo ${'"DATA_DIR_$i"'}')/etc/tomcat${TOMCAT_VER} &>> ${LOG}
	if [ $? -ne 0 ]; then
		echo -e ${FAILED}
		exit 1
	fi
	cp -a /usr/src/guacamole-${GUAC_VER}.war $(eval 'echo ${'"DATA_DIR_$i"'}')/var/lib/tomcat${TOMCAT_VER}/webapps/guacamole.war &>> ${LOG}
	if [ $? -ne 0 ]; then
		echo -e ${FAILED}
		exit 1
	fi
	cp -a /usr/src/guacamole-auth-jdbc-${GUAC_VER}/mysql/guacamole-auth-jdbc-mysql-${GUAC_VER}.jar $(eval 'echo ${'"DATA_DIR_$i"'}')/usr/share/tomcat${TOMCAT_VER}/.guacamole/extensions &>> ${LOG}
	if [ $? -ne 0 ]; then
		echo -e ${FAILED}
		exit 1
	fi
	cp -a /usr/src/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}-bin.jar $(eval 'echo ${'"DATA_DIR_$i"'}')/usr/share/tomcat${TOMCAT_VER}/.guacamole/lib/ &>> ${LOG}
	if [ $? -ne 0 ]; then
		echo -e ${FAILED}
		exit 1
	fi
	cp -a /usr/src/guacamole-auth-jdbc-${GUAC_VER}/mysql/guacamole-auth-jdbc-mysql-${GUAC_VER}.jar $(eval 'echo ${'"DATA_DIR_$i"'}')/usr/share/tomcat${TOMCAT_VER}/.guacamole/extensions/ &>> ${LOG}
	if [ $? -ne 0 ]; then
		echo -e ${FAILED}
		exit 1
	fi
	cp -a ${SRC_DIR}/etc/guacamole.properties $(eval 'echo ${'"DATA_DIR_$i"'}')/usr/share/tomcat${TOMCAT_VER}/.guacamole/ &>> ${LOG}
	if [ $? -ne 0 ]; then
		echo -e ${FAILED}
		exit 1
	fi
	cp -a -a ${SRC_DIR}/etc/server.xml $(eval 'echo ${'"DATA_DIR_$i"'}')/etc/tomcat${TOMCAT_VER}/server-guacamole.xml &>> ${LOG}
	if [ $? -ne 0 ]; then
		echo -e ${FAILED}
		exit 1
	fi

	cd $(eval 'echo ${'"DATA_DIR_$i"'}') &>> ${LOG}
	if [ $? -ne 0 ]; then
		echo -e ${FAILED}
		exit 1
	fi

	tar czf data.tar.gz * &>> ${LOG}
	if [ $? -ne 0 ]; then
		echo -e ${FAILED}
		exit 1
	fi

	find -type f -exec md5sum {} \; >> $(eval 'echo ${'"CONTROL_DIR_$i"'}')/md5sums 2>> ${LOG}
	if [ $? -ne 0 ]; then
		echo -e ${FAILED}
		exit 1
	fi

	echo 2.0 > $(eval 'echo ${'"CONTROL_DIR_$i"'}')/debian-binary 2>> ${LOG}
	if [ $? -ne 0 ]; then
		echo -e ${FAILED}
		exit 1
	fi

	cd $(eval 'echo ${'"CONTROL_DIR_$i"'}') &>> ${LOG}
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

	ar -cr ${DEBFILE} $(eval 'echo ${'"CONTROL_DIR_$i"'}')/debian-binary $(eval 'echo ${'"CONTROL_DIR_$i"'}')/control.tar.gz $(eval 'echo ${'"DATA_DIR_$i"'}')/data.tar.gz &>> ${LOG}
	if [ $? -ne 0 ]; then
		echo -e ${FAILED}
		exit 1
	fi
done

echo -e ${DONE}

rm -rf ${CONTROL_DIR_14} ${DATA_DIR_14} ${CONTROL_DIR_16} ${DATA_DIR_16} ${LOG}

# Build completed
echo -e "Build completed:"
ls -l /build/apt/pool/*/e/eve-ng-guacamole/eve-ng-guacamole_*.deb

