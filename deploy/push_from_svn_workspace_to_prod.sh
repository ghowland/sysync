#!/bin/bash

# Force OSX to stop copying stupid ._filename meta data files
export COPY_EXTENDED_ATTRIBUTES_DISABLE=true
export COPYFILE_DISABLE=true

echo " "
echo "MON-1 push is disabled!"
echo " "

UTIL_HOSTS='ops-1.prod.your.domain.com'

# Ensure we are in the correct directory
if [ ! -e sysync.py ] ; then
  echo 'error: This must be run from the local sysync root directory to properly create the tarball'
  exit 1
fi

# Remove old local tarball
rm /tmp/sysync.tar* 2> /dev/null

# Clean up python compiled files
find . -name '*.pyc' -exec rm {} \;

# Make sure we have the latest files to push out
svn up

# Tar it up
tar cf /tmp/sysync.tar -X tarball_exclude.txt *
gzip /tmp/sysync.tar

for UTIL_HOST in $UTIL_HOSTS
do
# Push tarball to prod
scp /tmp/sysync.tar.gz root@$UTIL_HOST:/var/www/html/repo/

# Put the boostrap and update scripts on the utility server
scp batch_sysync_commit.sh bootstrap_target_host.sh sysync_target_host.sh root@$UTIL_HOST:/home/scripts/
scp bootstrap_this_host_prod.sh bootstrap_this_host_softlayer.sh pull_prod_latest_to_local.sh root@$UTIL_HOST:/var/www/html/repo/
done
