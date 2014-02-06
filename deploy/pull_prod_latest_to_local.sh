#!/bin/bash
#
# Pull sysync information to local host
#
# Author: Geoff Howland <geoff@gmail.com>
#

TARBALL=sysync.tar.gz

WEBHOST=rpms

SYSYNC_URL=http://$WEBHOST/$TARBALL

# Only run this from production machines, this is enforced
#PROD_TEST=`hostname -f | grep some.prod.host.restrictive.server.at.your.domain.com`
#if [ "$PROD_TEST" == "" ] ; then
#  echo "error: $0 can only be run from production machines"
#  exit 1
#fi

# Fetch the latest sysync package, as a whole (not )
wget -q -O /tmp/$TARBALL $SYSYNC_URL
if [ $? -ne 0 ] ; then
  echo "error: Failed to fetch latest sysync tarball: $SYSYNC_URL"
  exit 1
fi

# Ensure the sysync directory exists
mkdir /etc/sysync 2> /dev/null

# Enter the sysync directory, to untar
cd /etc/sysync

# Clear all the current data, so that we are starting from scratch
rm -rf /etc/sysync/*

# Untar the latest sysync tarball into the sysync directory
tar zxf /tmp/sysync.tar.gz
if [ $? -ne 0 ] ; then
  echo "error: Failed to untar latest tarball: /tmp/sysync.tar.gz"
  exit 1
fi

