#!/bin/bash
CONTROL="/usr/src/eve-ng-public-dev/debian/dynamips_control.template"
CHANGELOG="/usr/src/eve-ng-public-dev/debian/dynamips_changelog.template"
SRC_DIR="/usr/src/eve-ng-public-dev"
DISTNAME=$(lsb_release -c -s)
ARCH=$(cat ${CONTROL} | grep Architecture | cut -d: -f2 | sed 's/ //')
BUILD_DIR="/build"
VERSION="$(cat ${SRC_DIR}/VERSION | cut -d- -f1)"
RELEASE="$(cat ${SRC_DIR}/VERSION | cut -d- -f2)"

# get source first
apt-get build-dep dynamips
apt-get install libpcap-dev libelf-dev
apt-get install dh-make
cd /usr/src
rm -fr dynamips*
wget -c "https://github.com/GNS3/dynamips/archive/v0.2.12.zip"
unzip v0.2.12.zip
cd dynamips-0.2.12/common
patch dynamips.c < /usr/src/eve-ng-public-dev/patch/dynamips-0.2.12.patch 
cd ..
dh_make -y --createorig -s -p eve-ng-dynamips
cat ${CONTROL} | sed "s/%VERSION%/${VERSION}/" | sed "s/%RELEASE%/${RELEASE}/" > debian/control
cat ${CHANGELOG} | sed "s/%VERSION%/${VERSION}/" | sed "s/%RELEASE%/${RELEASE}/" > debian/changelog
dpkg-buildpackage -b 2>/dev/null
mkdir -p ${BUILD_DIR}/apt/pool/${DISTNAME}/e/eve-ng-dynamips
mv ../eve-ng-dynamips_${VERSION}-${RELEASE}_amd64.deb ${BUILD_DIR}/apt/pool/${DISTNAME}/e/eve-ng-dynamips/
ls -l ${BUILD_DIR}/apt/pool/${DISTNAME}/e/eve-ng-dynamips/
