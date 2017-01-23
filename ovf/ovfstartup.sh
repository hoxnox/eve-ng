#!/bin/bash

# Fixing setcap
setcap cap_net_admin+ep /usr/sbin/tunctl
setcap cap_net_admin+ep /bin/ip
setcap cap_net_admin+ep /sbin/brctl
setcap cap_net_admin+ep /usr/bin/ovs-vsctl

# Deleting logs
rm -f /opt/unetlab/data/Logs/* /opt/unetlab/data/Exports/*
/usr/sbin/apache2ctl graceful

# Detecting new disk and resize Root Filesystem

# VM env ????
cat /proc/cpuinfo | grep -q hypervisor
if [ $? == 0 ]; then \
	echo Running Virtual Environment...
	echo Check new disks
	disks=$(dmesg | grep 'SCSI disk' | sed -e 's/.*\[//' -e 's/\].*//')
	for disk in $disks ; do \
		pvs | grep -q $disk
		if [ $? != 0 ]; then \
			# New disk found
			echo New disk $disk found
			pvcreate /dev/$disk
			echo -n "Detecting VG...."
			VGS=$(vgs --noheading | awk '{print $1}')
			echo $VGS
			vgextend $VGS /dev/$disk
			echo -n "Detecting ROOT FS..."
			ROOTLV=$(mount | grep ' / ' | awk '{print $1}')
			echo $ROOTLV
			lvextend -l +100%FREE $ROOTLV	
			echo Resizing ROOT FS
			resize2fs $ROOTLV
		fi
	done
fi

# Setting /etc/issue
echo "Eve-NG (default root password is 'eve')" > /etc/issue
if [[ -e "/sys/class/net/pnet0" ]]; then
    INTERFACE="pnet0"
    IP="$(ifconfig ${INTERFACE} 2> /dev/null | grep 'inet addr' | cut -d: -f2 | cut -d' ' -f1 | grep -E "^[0-9]+.[0-9]+.[0-9]+.[0-9]+$")"
    if [[ $? -eq 0 ]]; then
        echo "Use http://${IP}/" >> /etc/issue
    else
        echo "No IP address on interface ${INTERFACE}" >> /etc/issue
    fi
elif [[ -e "/sys/class/net/eth0" ]]; then
    INTERFACE="eth0"
    IP="$(ifconfig ${INTERFACE} 2> /dev/null | grep 'inet addr' | cut -d: -f2 | cut -d' ' -f1 | grep -E "^[0-9]+.[0-9]+.[0-9]+.[0-9]+$")"
    if [[ $? -eq 0 ]]; then
        echo "Use http://${IP}/" >> /etc/issue
    else
        echo "No IP address on interface ${INTERFACE}" >> /etc/issue
    fi
else
    INTERFACE=""
    IP=""
    echo "No suitable interface found" >> /etc/issue
fi
fgrep -e vmx -e svm /proc/cpuinfo 2>&1 > /dev/null
if [[ $? -eq 0 ]]; then
cat >> /etc/issue << EOF

EOF
else
cat >> /etc/issue << EOF

WARNING: neither Intel VT-x or AMD-V found

EOF
fi
