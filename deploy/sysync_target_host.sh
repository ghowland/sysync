#!/bin/bash
#
# Update sysync on host
#

# Host to update sysync on
HOST=$1

# Commit flag
COMMIT=$2

# Enforce commit acceptable values
if [ "$COMMIT" == "commit" -o "$COMMIT" == "" ] ; then
  # Do nothing
  /bin/true
else
  echo "error: Second argument should not be present or should be 'commit'.  No other value is acceptable."
  exit 1
fi

# Only run on the ops prod server
if [ `hostname -f` != "ops.prod.at.your.domain.com" -a `hostname -f` != "ops-1.prod.at.your.domain.com" ] ; then
  echo "error: This script should only be run from ops/ops-1."
  exit 1
fi

# Must have a host argument
if [ "$HOST" == "" ] ; then
  echo "usage: $0 <short hostname>"
  exit 1
fi 

if [ "$HOST" == "ops-1" ] ; then
  echo "error: WRONG!  Do not try to bootstrap ops-1.  We need that."
  exit 1
fi

scp /var/www/html/repo/pull_prod_latest_to_local.sh $HOST:/tmp/ 2>&1 > /dev/null
if [ $? -ne 0 ] ; then
  echo "error: Failed to push the Pull-From-Prod update script, which ensures it is pulling data correctly"
  exit 1
fi


ssh $HOST "chmod +x /tmp/pull_prod_latest_to_local.sh ; /tmp/pull_prod_latest_to_local.sh"
if [ $? -ne 0 ] ; then
  echo "error: Failed to execute the Pull-From-Prod update script, which updates the local sysync data on the target host"
  exit 1
fi

# Determine whether to run sysytem with commit, or just a dry-run (default)
if [ "$COMMIT" == "commit" ] ; then
  CMD="cd /etc/sysync ; ./sysync.py -C install"
else
  CMD="cd /etc/sysync ; ./sysync.py install"
fi

# Run the selected sysync command
ssh $HOST $CMD
if [ $? -ne 0 ] ; then
  echo "error: Failed to execute sysync on target host without errors"
  exit 1
fi

# Give a warning message that nothing was changed, if it worked
if [ "$COMMIT" != "commit" ] ; then
  echo
  echo "No commit performed.  Run again with final 'commit' argument to commit sysync changes."
  echo
fi
