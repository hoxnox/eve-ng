#!/bin/sh
#
# Eve-NG Ubuntu unattended iso installer build script
#  
# doc https://help.ubuntu.com/community/InstallCDCustomization
#
# original iso http://ubuntu.mirrors.ovh.net/ubuntu-releases/16.04.1/ubuntu-16.04-server-amd64.iso

wget -c http://ubuntu.mirrors.ovh.net/ubuntu-releases/16.04.1/ubuntu-16.04-server-amd64.iso -O /tmp/ubuntu-16.04-server-amd64.iso
mkdir /tmp/ubuntu-iso
mount -o loop /tmp/ubuntu-16.04-server-amd64.iso /tmp/ubuntu-iso
rsync -av /tmp/ubuntu-iso/ /tmp/eve-iso
cp /usr/src/eve-ng-public-dev/debian/txt.cfg /tmp/eve-iso/isolinux/
cp /usr/src/eve-ng-public-dev/debian/eve*.seed /tmp/eve-iso/preseed/
cp /usr/src/eve-ng-public-dev/debian/eve-setup.sh /tmp/eve-iso/install/
IMAGE=/tmp/EVE.iso BUILD=/tmp/eve-iso
mkisofs -r -V "EVE Install CD"             -cache-inodes             -J -l -b isolinux/isolinux.bin             -c isolinux/boot.cat -no-emul-boot             -boot-load-size 4 -boot-info-table             -o $IMAGE $BUILD
#rm -fr /tmp/eve-iso
umount /tmp/ubuntu-iso
rm -fr /tmp/ubuntu-iso
