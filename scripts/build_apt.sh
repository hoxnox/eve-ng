#!/bin/bash
BUILD_DIR="/build"
LOG="/tmp/eve_build.log"
SRC_DIR="/usr/src/eve-ng-public-dev"
DISTNAME=$(lsb_release -c -s)
TMP="$(mktemp -dt eve_tmp.XXXXXXXXXX)"

FAILED="\033[0;31mfailed\033[0m"
WARNING="\033[1;33mwarning\033[0m"
INFO="\033[0;34mblue\033[0m"
DONE="\033[0;32mdone\033[0m"

pgrep gpg-agent &> /dev/null
if [ $? -ne 0 ]; then
	echo -ne "Starting GPG agent... "
	gpg-agent --daemon --enable-ssh-support --write-env-file ~/.gpg-agent-info &> ${LOG}
	if [ $? -ne 0 ]; then
		echo -e ${WARNING}
	fi
	echo -e ${DONE}
fi

. ~/.gpg-agent-info &> ${LOG}
export GPG_AGENT_INFO
export SSH_AUTH_SOCK
export SSH_AGENT_PID

# Building the repository
echo -ne "Building environment (${DISTNAME})... "
mkdir -p ${BUILD_DIR}/apt/dists/${DISTNAME}/rrlabs/binary-amd64 &> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

cd ${BUILD_DIR}/apt
apt-ftparchive packages pool > ${BUILD_DIR}/apt/dists/${DISTNAME}/rrlabs/binary-amd64/Packages 2> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi
gzip -c ${BUILD_DIR}/apt/dists/${DISTNAME}/rrlabs/binary-amd64/Packages > ${BUILD_DIR}/apt/dists/${DISTNAME}/rrlabs/binary-amd64/Packages.gz 2> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

apt-ftparchive -o APT::FTPArchive::Release::Codename="${DISTNAME}" release dists/${DISTNAME} > ${TMP}/Release 2> ${LOG}
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

mv ${TMP}/Release ${BUILD_DIR}/apt/dists/${DISTNAME}/Release &> /dev/null
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

echo -e ${DONE}

echo -ne "Signing packages (${DISTNAME}:InRelease)... "
rm -f ${BUILD_DIR}/apt/dists/${DISTNAME}/InRelease ${BUILD_DIR}/apt/dists/${DISTNAME}/Release.gpg
gpg --use-agent --clearsign -o ${BUILD_DIR}/apt/dists/${DISTNAME}/InRelease ${BUILD_DIR}/apt/dists/${DISTNAME}/Release
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

echo -e ${DONE}

echo -ne "Signing packages (${DISTNAME}:Release.gpg)... "
gpg --use-agent -abs -o ${BUILD_DIR}/apt/dists/${DISTNAME}/Release.gpg ${BUILD_DIR}/apt/dists/${DISTNAME}/Release
if [ $? -ne 0 ]; then
	echo -e ${FAILED}
	exit 1
fi

echo -e ${DONE}

