#!/bin/bash

HOSTNAME=$1

# Enforce that this host was not already bootstrapped in some way
if [ "`hostname -f | grep .your.domain.com`" == "" ] ; then
  echo "error: This host has already been bootstrapped, because it has .your.domain.com in its hostname: `hostname -f`"
  exit 1
fi

# Enforce the hostname is passed in
if [ "$HOSTNAME" == "" ] ; then
  echo "usage: $0 <hostname>  --  Use the short name, not FQDN.  .your.domain.com is appended"
  exit 1
fi

# Update resolv.conf for minimal DNS (master DNS only, no suffix search)
echo nameserver 192.168.11.251 > /etc/resolv.conf
echo nameserver 192.168.11.252 > /etc/resolv.conf
echo search.your.domain.com >> /etc/resolv.conf

# Set the local hostname for bootup
cat /etc/sysconfig/network | grep -v HOSTNAME >> /tmp/network-bootstrap ; echo "HOSTNAME=$HOSTNAME.your.domain.com" >> /tmp/network-bootstrap
/bin/cp /tmp/network-bootstrap /etc/sysconfig/network
echo GATEWAY=192.168.11.1 >> /etc/sysconfig/network

touch /etc/cron.hourly/random-ntpdate-sync
#clean out old sysync tar as it fails if it has multiple copies with scp
/bin/rm -f /etc/sysync/sysync.tar.*

# Create a place for sysync to work
mkdir /etc/sysync 2> /dev/null
cd /etc/sysync

# Our PXE boot does not have wget, so we must grab it first
yum install -y wget

# do it before to get the repo data
wget http://corp-1/sysync.tar.gz
tar zxf sysync.tar.gz

/bin/cp -a /etc/sysync/deploy_corp/common_etc/yum.repos.d/* /etc/yum.repos.d

# Set the local hostname, during run time
hostname $HOSTNAME.your.domain.com

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

# Add basic auth keys | needs to be corp-1 when configured

# Set permissions on auth keys
#chmod 600 /root/.ssh/authorized_keys

# Get the latest sysync package (not server specific) and uncompress
cd /etc/sysync
wget http://rpms/sysync.tar.gz
tar zxf sysync.tar.gz

# Install this server
/etc/sysync/sysync.py -C install

