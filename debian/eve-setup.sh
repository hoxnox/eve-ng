#!/bin/sh
#Modify /etc/ssh/sshd_config with: PermitRootLogin yes
sed -i -e "s/PermitRootLogin .*/PermitRootLogin yes/" /etc/ssh/sshd_config
wget -O - http://everbx.podzone.net/repo/eczema@ecze.com.gpg.key | sudo apt-key add -
#wget -O - http://192.168.198.28/repo/eczema@ecze.com.gpg.key | sudo apt-key add -
apt-get -y install software-properties-common
sudo add-apt-repository "deb [arch=amd64]  http://everbx.podzone.net/repo xenial main"
#sudo add-apt-repository "deb [arch=amd64]  http://192.168.198.28/repo xenial main"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -y install eve-ng
/etc/init.d/mysql restart
DEBIAN_FRONTEND=noninteractive apt-get -y install eve-ng
mv /etc/rc.local /etc/eve-setup.sh
mv /etc/rc.local.ori /etc/rc.local
exit 0
