#!/bin/bash
BUILD_DIR="/build"
LOG="/tmp/eve_build.log"
SRC_DIR="/usr/src/eve-ng-public-dev"
CONTROL="${SRC_DIR}/debian/schema_control.template"
CONTROL_DIR="$(mktemp -dt eve_control.XXXXXXXXXX)"
DATA_DIR="$(mktemp -dt eve_data.XXXXXXXXXX)"
TMP="$(mktemp -dt eve_tmp.XXXXXXXXXX)"

FAILED="\033[0;31mfailed\033[0m"
WARNING="\033[1;33mwarning\033[0m"
INFO="\033[0;34mblue\033[0m"
DONE="\033[0;32mdone\033[0m"

# Environment for both Ubuntu 14.04 and 16.04
echo -ne "Building environment... "

VERSION="$(cat ${SRC_DIR}/VERSION 2>> ${LOG} | cut -d- -f1 2>> ${LOG})"
RELEASE="$(cat ${SRC_DIR}/VERSION 2>> ${LOG} | cut -d- -f2 2>> ${LOG})"

mkdir -p ${BUILD_DIR} ${CONTROL_DIR} ${DATA_DIR}/opt/unetlab /build/apt/pool/{trusty,xenial}/e/eve-ng-schema
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cat ${CONTROL} 2>> ${LOG} | sed "s/%VERSION%/${VERSION}/" 2>> ${LOG} | sed "s/%RELEASE%/${RELEASE}/" 2>> ${LOG} > ${CONTROL_DIR}/control
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi


# Copying schema
cd ${SRC_DIR}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cp -a schema ${DATA_DIR}/opt/unetlab/ &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

echo -e ${DONE}

# Building deb packages
echo -ne "Building deb packages... "

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

tar czf control.tar.gz md5sums control &>> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cd ${SRC_DIR}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

for i in trusty xenial; do
	DEBFILE="/build/apt/pool/${i}/e/eve-ng-schema/eve-ng-schema_${VERSION}-${RELEASE}_amd64.deb"
	ar -cr ${DEBFILE} ${CONTROL_DIR}/debian-binary ${CONTROL_DIR}/control.tar.gz $DATA_DIR/data.tar.gz &>> ${LOG}
	if [ $? -ne 0 ]; then
		echo -e ${FAILED}
		exit 1
	fi
done

echo -e ${DONE}

rm -rf ${CONTROL_DIR} ${DATA_DIR} ${LOG}

# Build completed
echo -e "Build completed:"
ls -l /build/apt/pool/*/e/eve-ng-schema/*.deb

