#!/bin/bash

DEBS="rsync sshpass"

usage(){
	echo "Usage: $0 -s <SourceIPAddress> -p <rootPassword>"
	exit 1
}

while getopts :s:p: o; do
	case ${o} in
		s)
			SRC=${OPTARG}
			;;
		p)
			export SSHPASS=${OPTARG}
			;;
		*)
			echo "ERROR: invalid argument"
			usage
			;;
	esac
done

if [ -z "${SRC}" ]; then
	echo "ERROR: source IP address not set"
	usage
fi

if [ -z "${SRC}" ]; then
	echo "ERROR: root password not set"
	usage
fi

# Install requirements
for DEB in ${DEBS}; do
	dpkg -l ${DEB} &> /dev/null || apt-get -qy install ${DEB} &> /dev/null
	if [ $? -ne 0 ]; then
		echo "ERROR: cannot install ${DEB}"
		exit 1
	fi
done

# Check connectivity
echo | nc -w3 ${SRC} 22 &> /dev/null
if [ $? -ne 0 ]; then
	echo "ERROR: cannot reach ${SRC}"
	exit 1
fi

# Checking password
sshpass -e ssh -o StrictHostKeyChecking=no root@${SRC} ls / &> /dev/null
if [ $? -ne 0 ]; then
	echo "ERROR: cannot login to ${SRC}"
	exit 1
fi

# Installing requirements
sshpass -e ssh root@${SRC} apt-get -qy install rsync &> /dev/null
if [ $? -ne 0 ]; then
	echo "ERROR: cannot install rsync to ${SRC}"
	exit 1
fi

# Importing FQDN and hosts
sshpass -e scp root@${SRC}:/etc/hostname /etc/hostname &> /dev/null
if [ $? -ne 0 ]; then
	echo "ERROR: failed import hostname"
	exit 1
fi
sshpass -e scp root@${SRC}:/etc/hosts /etc/hosts &> /dev/null
if [ $? -ne 0 ]; then
	echo "ERROR: failed import hosts file"
	exit 1
fi
hostnamectl set-hostname $(cat /etc/hostname) &> /dev/null
if [ $? -ne 0 ]; then
	echo "ERROR: failed to set local hostname"
	exit 1
fi

# Importing labs
echo "---------------------------------------------------------------------------"
echo " IMPORTING LABS"
echo "---------------------------------------------------------------------------"
sshpass -e rsync -av -e ssh root@${SRC}:/opt/unetlab/labs /opt/unetlab 
if [ $? -ne 0 ]; then
	echo "ERROR: failed to import labs"
	exit 1
fi

# Importing tmp
echo "---------------------------------------------------------------------------"
echo " IMPORTING ACTIVE LABS"
echo "---------------------------------------------------------------------------"
sshpass -e rsync -av -e ssh root@${SRC}:/opt/unetlab/tmp /opt/unetlab 
if [ $? -ne 0 ]; then
	echo "ERROR: failed to import active labs"
	exit 1
fi

# Importing addons
echo "---------------------------------------------------------------------------"
echo " IMPORTING ADDONS"
echo "---------------------------------------------------------------------------"
sshpass -e rsync -av -e ssh root@${SRC}:/opt/unetlab/addons /opt/unetlab 
if [ $? -ne 0 ]; then
	echo "ERROR: failed to import addons"
	exit 1
fi

# Importing users
echo "---------------------------------------------------------------------------"
echo " IMPORTING USERS"
echo "---------------------------------------------------------------------------"
sshpass -e scp root@${SRC}:/opt/unetlab/data/database.sdb /tmp/database.sdb &> /dev/null
if [ $? -ne 0 ]; then
	echo "ERROR: failed to import database.sdb"
	exit 1
fi
echo "SELECT password FROM users WHERE username = 'admin';" 2> /dev/null | sqlite3 /tmp/database.sdb 2> /dev/null | sed 's/^\(.*\)$/UPDATE users SET password = "\1" WHERE username = "admin";/g' 2> /dev/null | mysql -u eve-ng --password=eve-ng eve_ng_db &> /dev/null
if [ $? -ne 0 ]; then
	echo "ERROR: failed to update admin password"
	exit 1
fi

# Hostname
echo "---------------------------------------------------------------------------"
echo " MIGRATION COMPLETED"
echo "---------------------------------------------------------------------------"

