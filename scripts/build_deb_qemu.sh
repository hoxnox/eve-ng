#!/bin/bash
CONTROL="/usr/src/eve-ng-public-dev/debian/qemu_control.template"
SRC_DIR="/usr/src/eve-ng-public-dev"
DISTNAME=$(lsb_release -c -s)
ARCH=$(cat ${CONTROL} | grep Architecture | cut -d: -f2 | sed 's/ //')
BUILD_DIR="/build"
CONTROL_DIR="$(mktemp -dt)"
DATA_DIR="$(mktemp -dt)"
VERSION="$(cat ${SRC_DIR}/VERSION | cut -d- -f1)"
RELEASE="$(cat ${SRC_DIR}/VERSION | cut -d- -f2)"

cat ${CONTROL} | sed "s/%VERSION%/${VERSION}/" | sed "s/%RELEASE%/${RELEASE}/" > ${CONTROL_DIR}/control

# Download src
wget -O /usr/src/qemu-1.3.1.tar.bz2 -c "http://wiki.qemu-project.org/download/qemu-1.3.1.tar.bz2"
wget -O /usr/src/qemu-2.0.2.tar.bz2 -c "http://wiki.qemu-project.org/download/qemu-2.0.2.tar.bz2"
wget -O /usr/src/qemu-2.4.0.tar.bz2 -c "http://wiki.qemu-project.org/download/qemu-2.4.0.tar.bz2"

# get needed dev
# IMPORTANT ADD src in sources.list
apt-get build-dep qemu-kvm
apt-get install libtool-bin
# Extract

cd /usr/src/
tar -jxvf qemu-1.3.1.tar.bz2
tar -jxvf qemu-2.0.2.tar.bz2
tar -jxvf qemu-2.4.0.tar.bz2

cd /usr/src/qemu-1.3.1
patch -p0 < /usr/src/eve-ng-public-dev/patch/qemu-texi.patch
patch -p0 < /usr/src/eve-ng-public-dev/patch/qemu-1.3.1.patch
./configure --prefix=/opt/qemu-1.3.1 --target-list="i386-softmmu x86_64-softmmu" --enable-sdl --enable-vnc --disable-xen --enable-curses --enable-kvm --enable-uuid --audio-drv-list="alsa oss"
make 
make install

cd /usr/src/qemu-2.0.2
patch -p0 < /usr/src/eve-ng-public-dev/patch/qemu-2.1.2.patch
./configure --prefix=/opt/qemu-2.0.2 --target-list="i386-softmmu x86_64-softmmu" --enable-sdl --enable-vnc --disable-xen --enable-curses --enable-kvm --enable-uuid --audio-drv-list="alsa oss"
make
make install

cd /usr/src/qemu-2.4.0
./configure --prefix=/opt/qemu --target-list="i386-softmmu x86_64-softmmu" --enable-sdl --enable-vnc --disable-xen --enable-curses --enable-kvm --enable-uuid --audio-drv-list="alsa oss"
make
make install


# QEMU
mkdir -p ${DATA_DIR}/opt
cp -a /opt/qemu ${DATA_DIR}/opt
cp -a /opt/qemu-1.3.1 ${DATA_DIR}/opt
cp -a /opt/qemu-2.0.2 ${DATA_DIR}/opt

# Building the package
cd ${DATA_DIR}
tar czf data.tar.gz *
find -type f -exec md5sum {} \; >> ${CONTROL_DIR}/md5sums
echo 2.0 > ${CONTROL_DIR}/debian-binary
cd ${CONTROL_DIR}
tar czf control.tar.gz md5sums control
cd ${SRC_DIR}
mkdir -p ${BUILD_DIR}/apt/pool/${DISTNAME}/e/eve-ng-qemu
ar -cr ${BUILD_DIR}/apt/pool/${DISTNAME}/e/eve-ng-qemu/eve-ng-qemu_${VERSION}-${RELEASE}_${ARCH}.deb ${CONTROL_DIR}/debian-binary ${CONTROL_DIR}/control.tar.gz ${DATA_DIR}/data.tar.gz
rm -rf ${CONTROL_DIR} ${DATA_DIR}
ls -l /build/apt/pool/*/e/eve-ng-qemu/eve-ng-qemu_*.deb
