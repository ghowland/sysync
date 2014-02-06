#!/bin/bash

HOST=$1

# Only run on mon-1
if [ `hostname -f` != "ops.prod.your.domain.com" -a `hostname -f` != "ops-1.prod.your.domain.com" ] ; then
  echo "error: This script should only be run from mon-1"
  exit 1
fi

# Must have a host argument
if [ "$HOST" == "" ] ; then
  echo "usage: $0 <short hostname>"
  exit 1
fi 

if [ "$HOST" == "mon-1" -a "$HOST" == "ops-1" ] ; then
  echo "error: WRONG!  Do not try to bootstrap mon-1/ops-1.  We need that."
  exit 1
fi

echo
echo "Enter the root password for the target machine ($HOST) to bootstrap it:"
echo

# Run the bootstrap script on the target host
if [ `hostname -f` = "ops.prod.your.domain.com" ] ; then
  scp /var/www/html/repo/bootstrap_this_host_softlayer.sh $HOST:/tmp/bootstrap_this_host.sh
fi

if [ `hostname -f` = "ops-1.prod.your.domain.com" ] ; then
  scp /var/www/html/repo/bootstrap_this_host_prod.sh $HOST:/tmp/bootstrap_this_host.sh
fi

ssh $HOST "/tmp/bootstrap_this_host.sh $HOST"

if [ $? -eq 0 ] ; then
  echo
  echo "Bootstrap was successful.  Reboot the target host to test all services start correctly.  Sysync does not start or stop any services."
  echo
  echo "Enter \"reboot\" to reboot this host, and anything else to contine without reboot:"
  echo
  printf 'Confirm: '
  read confirm
  echo
  if [ "$confirm" == "reboot" ] ; then
    echo "Rebooting $HOST"
    ssh $HOST reboot
    echo
  else
    echo "No reboot will be performed"
    echo
  fi
else
  echo
  echo "Bootstrap failed."
  echo
fi
