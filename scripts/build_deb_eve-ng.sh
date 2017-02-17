#!/bin/bash
BUILD_DIR="/build"
LOG="/tmp/eve_build.log"
SRC_DIR="/usr/src/eve-ng-public-dev"
DISTNAME=$(lsb_release -c -s)
CONTROL="${SRC_DIR}/debian/eve-ng_${DISTNAME}_control.template"
CONTROL_DIR="$(mktemp -dt eve_control.XXXXXXXXXX)"
DATA_DIR="$(mktemp -dt eve_data.XXXXXXXXXX)"
TMP="$(mktemp -dt eve_tmp.XXXXXXXXXX)"
DEBIAN_FRONTEND="noninteractive"

FAILED="\033[0;31mfailed\033[0m"
WARNING="\033[1;33mwarning\033[0m"
INFO="\033[0;34mblue\033[0m"
DONE="\033[0;32mdone\033[0m"

MYSQL_ROOT_PASSWD="eve-ng"

# Environment
echo -ne "Building environment... "

VERSION="$(cat ${SRC_DIR}/VERSION 2>> ${LOG} | cut -d- -f1 2>> ${LOG})"
RELEASE="$(cat ${SRC_DIR}/VERSION 2>> ${LOG} | cut -d- -f2 2>> ${LOG})"

mkdir -p ${BUILD_DIR} ${CONTROL_DIR} ${DATA_DIR}/opt/unetlab/addons ${DATA_DIR}/opt/unetlab/data/Logs ${DATA_DIR}/opt/unetlab/labs ${DATA_DIR}/opt/unetlab/tmp ${DATA_DIR}/opt/unetlab/scripts ${DATA_DIR}/opt/unetlab/data/Exports &>> ${LOG} ${DATA_DIR}/opt/unetlab/wrappers ${DATA_DIR}/opt/unetlab/addons/iol/lib ${DATA_DIR}/opt/unetlab/addons/iol/bin ${DATA_DIR}/opt/unetlab/addons/dynamips ${DATA_DIR}/opt/unetlab/addons/qemu ${DATA_DIR}/etc/sudoers.d ${DATA_DIR}/etc/apache2/sites-available ${DATA_DIR}/etc/logrotate.d ${DATA_DIR}/usr/share/plymouth/themes ${DATA_DIR}/etc/initramfs-tools/conf.d ${DATA_DIR}/etc/apt/sources.list.d ${DATA_DIR}/opt/unetlab/html/files ${DATA_DIR}/etc/profile.d ${DATA_DIR}/etc/init /build/apt/pool/${DISTNAME}/e/eve-ng ${DATA_DIR}/etc/systemd/system
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cat ${CONTROL} 2>> ${LOG} | sed "s/%VERSION%/${VERSION}/" 2>> ${LOG} | sed "s/%RELEASE%/${RELEASE}/" 2>> ${LOG} > ${CONTROL_DIR}/control
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

# Copying html
cd ${SRC_DIR}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

rm -f html/includes/config.php &>> ${LOG}
rm -rf html/files &>> ${LOG}

cp -a html ${DATA_DIR}/opt/unetlab/ &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

# Setting version
cd ${SRC_DIR}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cat html/includes/init.php 2>> ${LOG} | sed "s/define('VERSION', .*/define('VERSION', '${VERSION}-${RELEASE}');/g" 2>> ${LOG} > ${DATA_DIR}/opt/unetlab/html/includes/init.php
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

# Copying scripts
cd ${SRC_DIR}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cp -a scripts ${DATA_DIR}/opt/unetlab/ &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cp -a IOUtools/iou_export ${DATA_DIR}/opt/unetlab/scripts/ &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

echo -e ${DONE}

# Compiling wrappers
echo -ne "Compiling wrappers... "

export CC="gcc"
export CFLAGS="-Wall -O2"
export INC="include/ts.c include/serial2udp.c include/afsocket.c include/tap.c include/cmd.c include/functions.c include/log.c"

cd ${SRC_DIR}/wrappers
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

${CC} ${CFLAGS} -o ${DATA_DIR}/opt/unetlab/wrappers/iol_wrapper ${INC} iol_wrapper.c iol_functions.c &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

${CC} ${CFLAGS} -o ${DATA_DIR}/opt/unetlab/wrappers/qemu_wrapper ${INC} qemu_wrapper.c qemu_functions.c &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

${CC} ${CFLAGS} -o ${DATA_DIR}/opt/unetlab/wrappers/dynamips_wrapper ${INC} dynamips_wrapper.c dynamips_functions.c &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cp -a unl_profile ${DATA_DIR}/opt/unetlab/wrappers/ &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cp -a unl_wrapper.php ${DATA_DIR}/opt/unetlab/wrappers/unl_wrapper &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cp -a nsenter ${DATA_DIR}/opt/unetlab/wrappers/ &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cp -a libcrypto.so.4 ${DATA_DIR}/opt/unetlab/addons/iol/lib/ &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

echo -e ${DONE}

# Copying OS files
echo -ne "Copying OS files... "

cd ${SRC_DIR}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cp -a etc/sudo.conf ${DATA_DIR}/etc/sudoers.d/unetlab &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cp -a etc/ovfstartup.service ${DATA_DIR}/etc/systemd/system/ovfstartup.service &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cp -a etc/cpulimit.service ${DATA_DIR}/etc/systemd/system/cpulimit.service &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cp -a etc/apache.conf ${DATA_DIR}/etc/apache2/sites-available/unetlab.conf &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cp -a etc/logrotate.conf ${DATA_DIR}/etc/logrotate.d/unetlab &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cp -a etc/initramfs.conf ${DATA_DIR}/etc/initramfs-tools/conf.d/ &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cp -a etc/sources.list ${DATA_DIR}/etc/apt/sources.list.d/unetlab.list &>> ${LOG}
if [ $? -ne 0 ]; then
        echo -e ${FAILED}
        exit 1
fi
sed -i -e 's/trusty/'${DISTNAME}'/' ${DATA_DIR}/etc/apt/sources.list.d/unetlab.list &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cp -a plymouth ${DATA_DIR}/usr/share/plymouth/themes/eveng &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cp -a ${SRC_DIR}/windows ${TMP}/UNetLab &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi
cd ${TMP} &>> ${LOG} && zip -r windows.zip UNetLab &>> ${LOG} && cd ${SRC_DIR} &>> ${LOG}
cp -a ${TMP}/windows.zip ${DATA_DIR}/opt/unetlab/html/files/ &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cp -a ovf ${DATA_DIR}/opt/ &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi
cp -a etc/profile.sh ${DATA_DIR}/etc/profile.d/ovf.sh &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi
cp -a etc/init.conf ${DATA_DIR}/etc/init/ovfconfig.conf &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

echo -e ${DONE}

# Permissions
echo -ne "Setting permissions... "

chown -R root:root ${DATA_DIR}/opt/unetlab &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi
chown -R www-data:www-data ${DATA_DIR}/opt/unetlab/data ${DATA_DIR}/opt/unetlab/labs &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi
chown -R root:unl ${DATA_DIR}/opt/unetlab/tmp &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi
chmod 2775 -R ${DATA_DIR}/opt/unetlab/data ${DATA_DIR}/opt/unetlab/labs ${DATA_DIR}/opt/unetlab/tmp &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi
chmod 0755 ${DATA_DIR}/opt/unetlab/scripts/* ${DATA_DIR}/opt/unetlab/wrappers/*_wrapper ${DATA_DIR}/opt/unetlab/wrappers/nsenter &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

chmod 644 ${DATA_DIR}/etc/sudoers.d/unetlab ${DATA_DIR}/etc/apache2/sites-available/unetlab.conf ${DATA_DIR}/etc/logrotate.d/unetlab ${DATA_DIR}/etc/initramfs-tools/conf.d/initramfs.conf ${DATA_DIR}/etc/apt/sources.list.d/unetlab.list ${DATA_DIR}/usr/share/plymouth/themes/eveng/* ${DATA_DIR}/etc/profile.d/ovf.sh ${DATA_DIR}/etc/init/ovfconfig.conf &>> ${LOG}
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

cat > ${CONTROL_DIR}/preinst << EOF
#!/bin/bash

echo -ne "Checking MySQL... "
echo "\q" | mysql -u root --password=eve-ng &> /dev/null
if [ \$? -ne 0 ]; then
        echo -e "${FAILED}"
        exit 1
fi

echo -e "${DONE}"

echo "\q" | mysql -u root --password=${MYSQL_ROOT_PASSWD} eve_ng_db &> /dev/null
if [ \$? -ne 0 ]; then
	echo -ne "Creating database and users... "
	echo "CREATE DATABASE IF NOT EXISTS eve_ng_db;" | mysql --host=localhost --user=root --password=${MYSQL_ROOT_PASSWD} &> /dev/null
	if [ \$? -ne 0 ]; then
		echo -e "${FAILED}"
		exit 1
	fi
	echo "GRANT ALL ON eve_ng_db.* TO 'eve-ng'@'localhost' IDENTIFIED BY 'eve-ng';" | mysql --host=localhost --user=root --password=eve-ng &> /dev/null
	if [ \$? -ne 0 ]; then
		echo -e "${FAILED}"
		exit 1
	fi
	cat /opt/unetlab/schema/unetlab-*.sql | mysql --host=localhost --user=root --password=${MYSQL_ROOT_PASSWD} eve_ng_db &> /dev/null
    if [ \$? -ne 0 ]; then
        echo -e "${FAILED}"
        exit 1
    fi

	echo -e "${DONE}"

	if [ -f /opt/unetlab/data/database.sdb ]; then
		echo -ne "Migrating users... "
		echo ".dump users " 2> /dev/null | sqlite3 /opt/unetlab/data/database.sdb 2> /dev/null | grep -i insert 2> /dev/null | sed -e 's/);/,1);/' -e 's/"/\`/g' 2> /dev/null | mysql -u eve-ng --password=eve-ng eve_ng_db &> /dev/null
		if [ $? -ne 0 ]; then
				echo -e "${FAILED}"
				exit 1
		fi
		mv /opt/unetlab/data/database.sdb /opt/unetlab/data/database.sdb.old &> /dev/null
		if [ $? -ne 0 ]; then
				echo -e "${FAILED}"
				exit 1
		fi

		echo -e "${DONE}"
	else
		echo -ne "Adding admin user... "
		echo "INSERT INTO users VALUES ('admin',NULL,'root@localhost',-1,'UNetLab Administrator','dddc487d503fdb607bc113821a7416cfd67a3abf77f4ec87ee5797449bdca796',NULL,'','admin','',1);" | mysql --host=localhost --user=root --password=${MYSQL_ROOT_PASSWD} eve_ng_db &> /dev/null
		if [ $? -ne 0 ]; then
				echo -e "${FAILED}"
				exit 1
		fi

		echo -e "${DONE}"
	fi
fi
EOF

cat > ${CONTROL_DIR}/postinst << EOF
#!/bin/bash
systemctl --system daemon-reload &> /dev/null
systemctl enable ovfstartup &> /dev/null
systemctl enable cpulimit &> /dev/null
systemctl start ovfstartup &> /dev/null
systemctl start cpulimit &> /dev/null
groupadd -g 32768 -f unl &> /dev/null
a2enmod rewrite &> /dev/null
a2enmod proxy_html &> /dev/null
a2enmod proxy_http &> /dev/null
a2enmod proxy_wstunnel &> /dev/null
a2enmod xml2enc &> /dev/null
a2dissite 000-default &> /dev/null
a2ensite unetlab &> /dev/null
service apache2 restart &> /dev/null
BAREPARAMS=\$(cat /etc/default/BAREPARAMS 2>/dev/null || true ) &> /dev/null
sed -i 's/.*GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash vga=788"/g' /etc/default/grub &> /dev/null
sed -i 's/.*GRUB_GFXMODE=.*/GRUB_GFXMODE="800x600"/g' /etc/default/grub &> /dev/null
sed -i 's/.*GRUB_HIDDEN_TIMEOUT=.*/GRUB_HIDDEN_TIMEOUT=2/g' /etc/default/grub &> /dev/null
sed -i 's/.*GRUB_HIDDEN_TIMEOUT_QUIET=.*/GRUB_HIDDEN_TIMEOUT_QUIET=true/g' /etc/default/grub &> /dev/null
sed -i 's/.*GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/g' /etc/default/grub &> /dev/null
sed -i 's/.*GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX="net.ifnames=0 '"\$BAREPARAMS"' "/g' /etc/default/grub &> /dev/null
sed -i "s/^ServerName.*$/ServerName \$(hostname -f)/g" /etc/apache2/sites-available/unetlab.conf &> /dev/null
update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/eveng/eveng.plymouth 100 &> /dev/null
update-initramfs -u -k all &> /dev/null
update-grub2 &> /dev/null
fgrep "xml.cisco.com" /etc/hosts &> /dev/null || echo 127.0.0.127 xml.cisco.com >> /etc/hosts 2> /dev/null
sed -i 's/.*::.*//' /etc/hosts &> /dev/null
# Fix tunctl
setcap cap_net_admin+ep /usr/sbin/tunctl &> /dev/null
setcap cap_net_admin+ep /bin/ip &> /dev/null
setcap cap_net_admin+ep /sbin/brctl &> /dev/null
setcap cap_net_admin+ep /usr/bin/ovs-vsctl &> /dev/null
# Check for Intel VT-x/AMD-V
fgrep -e vmx -e svm /proc/cpuinfo &> /dev/null || echo -e "\033[1;33mWARNING: neither Intel VT-x or AMD-V found\033[0m"
# Cleaning logs
rm -f /opt/unetlab/data/Logs/* &> /dev/null
/usr/sbin/apache2ctl graceful &> /dev/null
# Cleaning exports
rm -f /opt/unetlab/data/Exports/* &> /dev/null
# Cleaning swp files
find /opt/unetlab/labs/ -name "*.swp" -exec rm -f {} \; &> /dev/null
# Fixing permissions
/opt/unetlab/wrappers/unl_wrapper -a fixpermissions &> /dev/null
# Mark official kernels as hold
#apt-mark hold  \$(dpkg -l | grep -e linux-image -e linux-headers -e linux-generic | grep -v eve-ng | awk '{print \$2}') &> /dev/null
# Remove non EVE-NG kernel
apt-get -y purge \$(dpkg -l | grep -e linux-image -e linux-headers -e linux-generic | grep -v eve-ng | awk '{print \$2}') &> /dev/null
# Additional fixes
find /opt/unetlab/tmp/ -name "nvram_*" -exec /opt/unetlab/scripts/fix_iol_nvram.sh "{}" \; &> /dev/null
EOF

DEBFILE="/build/apt/pool/${DISTNAME}/e/eve-ng/eve-ng_${VERSION}-${RELEASE}_amd64.deb"
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
ls -l /build/apt/pool/${DISTNAME}/e/eve-ng/eve-ng_*.deb

