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

# Migrating labs
echo "IMPORTING LABS:"
sshpass -e rsync -av -e ssh root@${SRC}:/opt/unetlab/labs /opt/unetlab 
if [ $? -ne 0 ]; then
	echo "ERROR: failed to import labs"
	exit 1
fi

# Migrating tmp
echo "IMPORTING ACTIVE LABS:"
sshpass -e rsync -av -e ssh root@${SRC}:/opt/unetlab/tmp /opt/unetlab 
if [ $? -ne 0 ]; then
	echo "ERROR: failed to import active labs"
	exit 1
fi

# Migrating addons
echo "IMPORTING ADDONS:"
sshpass -e rsync -av -e ssh root@${SRC}:/opt/unetlab/addons /opt/unetlab 
if [ $? -ne 0 ]; then
	echo "ERROR: failed to import addons"
	exit 1
fi

# Migrating users

# Hostname

