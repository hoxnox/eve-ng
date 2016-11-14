#!/bin/bash
BUILD_DIR="/build"
LOG="/tmp/eve_build.log"
SRC_DIR="/usr/src/eve-ng-public-dev"
CONTROL="${SRC_DIR}/debian/eve-ng_control.template"
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

MYSQL_ROOT_PASSWD="eve-ng"

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

mkdir -p ${BUILD_DIR} {${CONTROL_DIR_14},${CONTROL_DIR_16}} {${DATA_DIR_14},${DATA_DIR_16}}/opt/unetlab/addons {${DATA_DIR_14},${DATA_DIR_16}}/opt/unetlab/data/Logs {${DATA_DIR_14},${DATA_DIR_16}}/opt/unetlab/labs {${DATA_DIR_14},${DATA_DIR_16}}/opt/unetlab/tmp {${DATA_DIR_14},${DATA_DIR_16}}/opt/unetlab/scripts {${DATA_DIR_14},${DATA_DIR_16}}/opt/unetlab/data/Exports &>> ${LOG} {${DATA_DIR_14},${DATA_DIR_16}}/opt/unetlab/wrappers {${DATA_DIR_14},${DATA_DIR_16}}/opt/unetlab/addons/iol/lib {${DATA_DIR_14},${DATA_DIR_16}}/opt/unetlab/addons/iol/bin {${DATA_DIR_14},${DATA_DIR_16}}/opt/unetlab/addons/dynamips {${DATA_DIR_14},${DATA_DIR_16}}/opt/unetlab/addons/qemu {${DATA_DIR_14},${DATA_DIR_16}}/etc/sudoers.d {${DATA_DIR_14},${DATA_DIR_16}}/etc/apache2/sites-available {${DATA_DIR_14},${DATA_DIR_16}}/etc/logrotate.d {${DATA_DIR_14},${DATA_DIR_16}}/lib/plymouth/themes/unetlab {${DATA_DIR_14},${DATA_DIR_16}}/etc/initramfs-tools/conf.d {${DATA_DIR_14},${DATA_DIR_16}}/etc/apt/sources.list.d {${DATA_DIR_14},${DATA_DIR_16}}/opt/unetlab/html/files {${DATA_DIR_14},${DATA_DIR_16}}/etc/profile.d {${DATA_DIR_14},${DATA_DIR_16}}/etc/init /build/apt/pool/{trusty,xenial}/e/eve-ng
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

# Copying html
cd ${SRC_DIR}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

rm -f html/includes/config.php &>> ${LOG}
rm -rf html/files &>> ${LOG}

cp -a html ${DATA_DIR_14}/opt/unetlab/ &>> ${LOG} && cp -a html ${DATA_DIR_16}/opt/unetlab/ &>> ${LOG}
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

cat html/includes/init.php 2>> ${LOG} | sed "s/define('VERSION', .*/define('VERSION', '${VERSION}-${RELEASE}');/g" 2>> ${LOG} > ${DATA_DIR_14}/opt/unetlab/html/includes/init.php && cat html/includes/init.php 2>> ${LOG} | sed "s/define('VERSION', .*/define('VERSION', '${VERSION}-${RELEASE}');/g" 2>> ${LOG} > ${DATA_DIR_16}/opt/unetlab/html/includes/init.php
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

cp -a scripts ${DATA_DIR_14}/opt/unetlab/ &>> ${LOG} && cp -a scripts ${DATA_DIR_16}/opt/unetlab/ &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cp -a IOUtools/iou_export ${DATA_DIR_14}/opt/unetlab/scripts/ &>> ${LOG} && cp -a IOUtools/iou_export ${DATA_DIR_16}/opt/unetlab/scripts/ &>> ${LOG}
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

${CC} ${CFLAGS} -o ${DATA_DIR_14}/opt/unetlab/wrappers/iol_wrapper ${INC} iol_wrapper.c iol_functions.c &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cp -a ${DATA_DIR_14}/opt/unetlab/wrappers/iol_wrapper ${DATA_DIR_16}/opt/unetlab/wrappers/ &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

${CC} ${CFLAGS} -o ${DATA_DIR_14}/opt/unetlab/wrappers/qemu_wrapper ${INC} qemu_wrapper.c qemu_functions.c &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cp -a ${DATA_DIR_14}/opt/unetlab/wrappers/qemu_wrapper ${DATA_DIR_16}/opt/unetlab/wrappers/ &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

${CC} ${CFLAGS} -o ${DATA_DIR_14}/opt/unetlab/wrappers/dynamips_wrapper ${INC} dynamips_wrapper.c dynamips_functions.c &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cp -a ${DATA_DIR_14}/opt/unetlab/wrappers/dynamips_wrapper ${DATA_DIR_16}/opt/unetlab/wrappers/ &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cp -a unl_profile ${DATA_DIR_14}/opt/unetlab/wrappers/ &>> ${LOG} && cp -a unl_profile ${DATA_DIR_16}/opt/unetlab/wrappers/ &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cp -a unl_wrapper.php ${DATA_DIR_14}/opt/unetlab/wrappers/unl_wrapper &>> ${LOG} && cp -a unl_wrapper.php ${DATA_DIR_16}/opt/unetlab/wrappers/unl_wrapper &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cp -a nsenter ${DATA_DIR_14}/opt/unetlab/wrappers/ &>> ${LOG} && cp -a nsenter ${DATA_DIR_16}/opt/unetlab/wrappers/ &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cp -a libcrypto.so.4 ${DATA_DIR_14}/opt/unetlab/addons/iol/lib/ &>> ${LOG} && cp -a libcrypto.so.4 ${DATA_DIR_16}/opt/unetlab/addons/iol/lib/ &>> ${LOG}
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

cp -a etc/sudo.conf ${DATA_DIR_14}/etc/sudoers.d/unetlab &>> ${LOG} && cp -a etc/sudo.conf ${DATA_DIR_16}/etc/sudoers.d/unetlab &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cp -a etc/apache.conf ${DATA_DIR_14}/etc/apache2/sites-available/unetlab.conf &>> ${LOG} && cp -a etc/apache.conf ${DATA_DIR_16}/etc/apache2/sites-available/unetlab.conf
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cp -a etc/logrotate.conf ${DATA_DIR_14}/etc/logrotate.d/unetlab &>> ${LOG} && cp -a etc/logrotate.conf ${DATA_DIR_16}/etc/logrotate.d/unetlab
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cp -a etc/initramfs.conf ${DATA_DIR_14}/etc/initramfs-tools/conf.d/ &>> ${LOG} && cp -a etc/initramfs.conf ${DATA_DIR_16}/etc/initramfs-tools/conf.d/ &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cp -a etc/sources.list ${DATA_DIR_14}/etc/apt/sources.list.d/unetlab.list &>> ${LOG} && cp -a etc/sources.list ${DATA_DIR_16}/etc/apt/sources.list.d/unetlab.list &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cp -a plymouth ${DATA_DIR_14}/lib/plymouth/themes/unetlab &>> ${LOG} && cp -a plymouth ${DATA_DIR_16}/lib/plymouth/themes/unetlab &>> ${LOG}
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
cp -a ${TMP}/windows.zip ${DATA_DIR_14}/opt/unetlab/html/files/ &>> ${LOG} && cp -a ${TMP}/windows.zip ${DATA_DIR_16}/opt/unetlab/html/files/ &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cp -a ovf ${DATA_DIR_14}/opt/ &>> ${LOG} && cp -a ovf ${DATA_DIR_16}/opt/ &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi
cp -a etc/profile.sh ${DATA_DIR_14}/etc/profile.d/ovf.sh &>> ${LOG} && cp -a etc/profile.sh ${DATA_DIR_16}/etc/profile.d/ovf.sh &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi
cp -a etc/init.conf ${DATA_DIR_14}/etc/init/ovfconfig.conf &>> ${LOG} && cp -a etc/init.conf ${DATA_DIR_16}/etc/init/ovfconfig.conf &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

echo -e ${DONE}

# Permissions
echo -ne "Setting permissions... "

chown -R root:root {${DATA_DIR_14},${DATA_DIR_16}}/opt/unetlab &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi
chown -R www-data:www-data {${DATA_DIR_14},${DATA_DIR_16}}/opt/unetlab/data {${DATA_DIR_14},${DATA_DIR_16}}/opt/unetlab/labs &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi
chown -R root:unl {${DATA_DIR_14},${DATA_DIR_16}}/opt/unetlab/tmp &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi
chmod 2775 -R {${DATA_DIR_14},${DATA_DIR_16}}/opt/unetlab/data {${DATA_DIR_14},${DATA_DIR_16}}/opt/unetlab/labs {${DATA_DIR_14},${DATA_DIR_16}}/opt/unetlab/tmp &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi
chmod 0755 {${DATA_DIR_14},${DATA_DIR_16}}/opt/unetlab/scripts/* {${DATA_DIR_14},${DATA_DIR_16}}/opt/unetlab/wrappers/*_wrapper {${DATA_DIR_14},${DATA_DIR_16}}/opt/unetlab/wrappers/nsenter &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

chmod 644 {${DATA_DIR_14},${DATA_DIR_16}}/etc/sudoers.d/unetlab {${DATA_DIR_14},${DATA_DIR_16}}/etc/apache2/sites-available/unetlab.conf {${DATA_DIR_14},${DATA_DIR_16}}/etc/logrotate.d/unetlab {${DATA_DIR_14},${DATA_DIR_16}}/etc/initramfs-tools/conf.d/initramfs.conf {${DATA_DIR_14},${DATA_DIR_16}}/etc/apt/sources.list.d/unetlab.list {${DATA_DIR_14},${DATA_DIR_16}}/lib/plymouth/themes/unetlab/* {${DATA_DIR_14},${DATA_DIR_16}}/etc/profile.d/ovf.sh {${DATA_DIR_14},${DATA_DIR_16}}/etc/init/ovfconfig.conf &>> ${LOG}
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

cat > ${CONTROL_DIR_14}/preinst << EOF
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
	fi
fi
EOF

cp -a ${CONTROL_DIR_14}/preinst ${CONTROL_DIR_16} &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cat > ${CONTROL_DIR_14}/postinst << EOF
#!/bin/bash
groupadd -g 32768 -f unl &> /dev/null
a2enmod rewrite &> /dev/null
a2enmod proxy_html &> /dev/null
a2enmod proxy_http &> /dev/null
a2enmod proxy_wstunnel &> /dev/null
a2enmod xml2enc &> /dev/null
a2dissite 000-default &> /dev/null
a2ensite unetlab &> /dev/null
service apache2 restart &> /dev/null
sed -i 's/.*GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash vga=788"/g' /etc/default/grub &> /dev/null
sed -i 's/.*GRUB_GFXMODE=.*/GRUB_GFXMODE="800x600"/g' /etc/default/grub &> /dev/null
sed -i 's/.*GRUB_HIDDEN_TIMEOUT=.*/GRUB_HIDDEN_TIMEOUT=2/g' /etc/default/grub &> /dev/null
sed -i 's/.*GRUB_HIDDEN_TIMEOUT_QUIET=.*/GRUB_HIDDEN_TIMEOUT_QUIET=true/g' /etc/default/grub &> /dev/null
sed -i 's/.*GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/g' /etc/default/grub &> /dev/null
sed -i "s/^ServerName.*$/ServerName \$(hostname -f)/g" /etc/apache2/sites-available/unetlab.conf &> /dev/null
update-alternatives --install /lib/plymouth/themes/default.plymouth default.plymouth /lib/plymouth/themes/unetlab/unetlab.plymouth 100 &> /dev/null
update-initramfs -u &> /dev/null
update-grub2 &> /dev/null
fgrep "xml.cisco.com" /etc/hosts &> /dev/null || echo 127.0.0.127 xml.cisco.com >> /etc/hosts 2> /dev/null
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
apt-mark hold  \$(dpkg -l | grep -e linux-image -e linux-headers -e linux-generic | grep -v unetlab | awk '{print \$2}') &> /dev/null
# Additional fixes
find /opt/unetlab/tmp/ -name "nvram_*" -exec /opt/unetlab/scripts/fix_iol_nvram.sh "{}" \; &> /dev/null
EOF

cp -a ${CONTROL_DIR_14}/postinst ${CONTROL_DIR_16} &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

for i in 14 16; do
	if [ ${i} -eq 14 ]; then
		DEBFILE="/build/apt/pool/trusty/e/eve-ng/eve-ng_${VERSION}-${RELEASE}_amd64.deb"
	else
		DEBFILE="/build/apt/pool/xenial/e/eve-ng/eve-ng_${VERSION}-${RELEASE}_amd64.deb"
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
ls -l /build/apt/pool/*/e/eve-ng/eve-ng_*.deb

