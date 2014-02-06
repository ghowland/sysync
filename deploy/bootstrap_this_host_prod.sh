#!/bin/bash

HOSTNAME=$1

# Enforce that this host was not already bootstrapped in some way
if [ "`hostname -f | grep .prod.your.domain.com`" != "" ] ; then
  echo "error: This host has already been bootstrapped, because it has .prod.your.domain.com in its hostname: `hostname -f`"
  exit 1
fi

# Enforce the hostname is passed in
if [ "$HOSTNAME" == "" ] ; then
  echo "usage: $0 <hostname>  --  Use the short name, not FQDN. .prod.your.domain.com is appended"
  exit 1
fi

# Update resolv.conf for minimal DNS (master DNS only, no suffix search)
echo nameserver 10.2.0.21 > /etc/resolv.conf
echo search.prod.your.domain.com prod.your.domain.com >> /etc/resolv.conf

# Set the local hostname for bootup
cat /etc/sysconfig/network | grep -v HOSTNAME >> /tmp/network-bootstrap ; echo "HOSTNAME=$HOSTNAME.prod.your.domain.com" >> /tmp/network-bootstrap
/bin/cp /tmp/network-bootstrap /etc/sysconfig/network
echo GATEWAY=10.2.0.1 >> /etc/sysconfig/network

touch /etc/cron.hourly/random-ntpdate-sync
#clean out old sysync tar as it fails if it has multiple copies with scp
/bin/rm -f /etc/sysync/sysync.tar.*

# Create a place for sysync to work
mkdir /etc/sysync 2> /dev/null
cd /etc/sysync

# Our PXE boot does not have wget, so we must grab it first
yum install -y wget

# do it before to get the repo data
wget http://ops-1/sysync.tar.gz
tar zxf sysync.tar.gz

/bin/cp -a /etc/sysync/deploy/common_etc/yum.repos.d/* /etc/yum.repos.d

# Set the local hostname, during run time
hostname $HOSTNAME.prod.your.domain.com

# adding kals account
groupadd -g 200 sysadmin ; useradd -u 814 -g 200 kpanchal

# Add repos for yum installation
# need our repo files as some module install fails, moved cp from common_etc
#echo '[dag]' > /etc/yum.repos.d/dag.repo
#echo name=Dag RPM Repository for Red Hat Enterprise Linux >> /etc/yum.repos.d/dag.repo
#echo baseurl=http://rpms/5.5/dag >> /etc/yum.repos.d/dag.repo
#echo gpgcheck=0 >> /etc/yum.repos.d/dag.repo >> /etc/yum.repos.d/dag.repo
#echo enabled=1 >> /etc/yum.repos.d/dag.repo >> /etc/yum.repos.d/dag.repo

#echo '[epel]' > /etc/yum.repos.d/epel.repo
#echo name=EPEL RPM Repository for Fedora Linux >> /etc/yum.repos.d/epel.repo
#echo baseurl=http://rpms/5.5/epel >> /etc/yum.repos.d/epel.repo
#echo gpgcheck=0 >> /etc/yum.repos.d/epel.repo
#echo enabled=1 >> /etc/yum.repos.d/epel.repo

#append option for disabling ipv6 module 
#echo alias net-pf-10 off >> /etc/modprobe.conf
#grep initrd-2 /etc/grub.conf | awk '{print $2}' | cut -f 2 -d / | head -1 > /tmp/kern
#mkinitrd -f /boot/`cat /tmp/kern` `uname -r`
#tune2fs -o journal_data_writeback `df | head -2 | tail -1 | awk '{print $1}'`
#sed s/ext3.*defaults/"ext3   defaults,noatime,nodiratime"/ /etc/fstab > /tmp/newfstab
#/bin/cp -f /etc/fstab /etc/fstab.old
#/bin/cp -f /tmp/newfstab /etc/fstab
chmod 644 /etc/grub.conf /var/log/messages

# create default 4gb swap file if needed
if [ ! -f /swapfile ] ; then
    dd if=/dev/zero of=/swapfile bs=1024k count=4000 
    mkswap /swapfile 
    echo /swapfile swap swap defaults 0 0 >>  /etc/fstab
fi



# Clean up any existing yum repo data, so we are really using our sources
yum clean all

# yum install xfs packages for filesystem
yum install -y kmod-xfs.x86_64 xfsdump.x86_64 xfsprogs.x86_64 parted man



# exclude hadoop boxes from /data due to root disk being full disk
hostname | grep hadoop
if [ $? -eq 1 ] ; then
    # fill rest of primary disk with /data partition
    parted /dev/sda unit cyl print | grep 1274cyl
    if [ $? -eq 0 ] ; then 
	parted /dev/sda -- mkpart primary ext3 1275cyl -1cyl
    else
	echo partition mapping is OFF on the machine!
	exit 1
    fi

    parted /dev/sda unit cyl print | grep /dev/sda2
    if [ $? -eq 0 ] ; then 
	echo partition 2 already present skipping
    else
	echo "/dev/sda2    /data  xfs defaults,noatime,nodiratime  0 0"  >> /etc/fstab
    fi

    # not doing -f just incase there was old filesystem with xfs data
    mkfs.xfs   /dev/sda2 
    mkdir /data
    mount /dev/sda2 /data

fi



# install pigz gzip with multicore support
yum install -y pigz

# Remove any existing bind, as it conflicts with our yum repos
yum remove -y bind-libs bind-devel bind-libs bind-utils bind-devel
# Remove ghostscript for the same reasons
yum remove -y ghostscript

# Install Python2.4 YAML and JSON libraries, which sysync requires
yum install -y python-json python-yaml

# Clean up any existing yum repo data, so we are really using our sources
#NOTE(g): Repeating, because we are seeing problems with this
/usr/bin/yum clean all

# Create the root .ssh directory, with correct permissions
mkdir /root/.ssh 2> /dev/null
chmod 700 /root/.ssh

# Add basic auth keys
echo ssh-dss AAAAB3NzaC1kc3MAAACBAP2i9O7h6qbLbPLg5QQBi9zr1YWnzazZu2YQ6hgdaVBCltJIp+LbHs3OdhIiVcNeruv0RMYeJhcsHuPTSFIkk3N8IFfv3qUgRF58UypiwTcHTBbzZoD1SYXsDGwveGAAILxvfoU2WpVIKHBmCHCawIjFeanUs+aKwB1VdfPbyt8VAAAAFQCz3DwHFuh0JGq2CerKXNcNEDYSEwAAAIEAk8QHco4eJqE/6/eiswxYd7p95/ReiKNIzByKXx4Lb3icifJICF0ATrfu1yG5az0U7obMw+XUchYnrQsYVXVxqebr9UwWxkwpCS+A6dhmcnYeyiwYkC9uxyaqVP6Les5YHaQ+jJ8sugZxNOR533HhisPSeJfhqAtf46eJQJkqQCcAAACAIt+P/sk1cS+4pW3VPTFa1RSp1UV6tgnxU9g+LrlMFzw+VUXutgxr0+laUM2zM8i8XgESu+1irKmObPDCI286EFZDfEUhKNyHYkU3rCBa82w7MkutePomUk3a0rla56uuhQs7uODTmJjbUA1/CXyKKxAs80PBMlZX/+T1NB43tC8= root@ops-1 > /root/.ssh/authorized_keys

# Set permissions on auth keys
chmod 600 /root/.ssh/authorized_keys

# Get the latest sysync package (not server specific) and uncompress
cd /etc/sysync
wget http://rpms/sysync.tar.gz
tar zxf sysync.tar.gz

# Install this server
/etc/sysync/sysync.py -C install

