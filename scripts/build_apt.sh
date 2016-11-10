#!/bin/bash
BUILD_DIR="/build"
LOG="/tmp/eve_build.log"
SRC_DIR="/usr/src/eve-ng-public-dev"
TMP="$(mktemp -dt eve_tmp.XXXXXXXXXX)"

FAILED="\033[0;31mfailed\033[0m"
WARNING="\033[1;33mwarning\033[0m"
INFO="\033[0;34mblue\033[0m"
DONE="\033[0;32mdone\033[0m"

# Building the repository
echo -ne "Building environment... "
mkdir -p ${BUILD_DIR}/apt/dists/trusty/rrlabs/binary-amd64 &> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cd ${BUILD_DIR}/apt
apt-ftparchive packages pool > ${BUILD_DIR}/apt/dists/trusty/rrlabs/binary-amd64/Packages 2> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi
gzip -c ${BUILD_DIR}/apt/dists/trusty/rrlabs/binary-amd64/Packages > ${BUILD_DIR}/apt/dists/trusty/rrlabs/binary-amd64/Packages.gz 2> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

apt-ftparchive -o APT::FTPArchive::Release::Codename="trusty" release dists/trusty > ${TMP}/Release 2> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

mv ${TMP}/Release ${BUILD_DIR}/apt/dists/trusty/Release &> /dev/null
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

echo -e ${DONE}

echo -ne "Signing packages (InRelease)... "
rm -f ${BUILD_DIR}/apt/dists/trusty/InRelease ${BUILD_DIR}/apt/dists/trusty/Release.gpg
gpg --clearsign -o ${BUILD_DIR}/apt/dists/trusty/InRelease ${BUILD_DIR}/apt/dists/trusty/Release
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

echo -e ${DONE}

echo -ne "Signing packages (Release.gpg)... "
gpg -abs -o ${BUILD_DIR}/apt/dists/trusty/Release.gpg ${BUILD_DIR}/apt/dists/trusty/Release
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

echo -e ${DONE}
