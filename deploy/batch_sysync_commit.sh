#!/bin/bash

HOSTPREFIX=$1
START=$2
END=$3

function Usage {
  echo
  echo "usage: $0 hostprefix startnumber <endnumber>"
  echo
  echo "hostprefix is added to the host number, which is between startnumber and endnumber."
  echo "example: $0 app 64 93"
  echo "  This example will run sysync on app-63 to app-93."
  echo
  echo "Valid host prefixes: app, script, mon, db-fio, logging, hadoop"
  exit 1
}

# Verify args
if [ "$HOSTPREFIX" == "" ] ; then
  echo "error: Must specify hostgroup prefix (ex: scripts, app, mon, etc)"
  Usage
fi
if [ "$START" == "" ] ; then
  echo "error: No start number specified.  If only one system is to be pushed, this is the only numeric argument needed"
  Usage
fi
if [[ "$START" != [0-9]* ]]; then
  echo "error: Start number is not an integer"
  Usage
fi
if [ "$END" == "" ] ; then
  # If there is no end, then use the start
  END=$START
fi
if [[ "$END" != [0-9]* ]]; then
  echo "error: End number is not an integer"
  Usage
fi


# Verify host prefix
if [ "$HOSTPREFIX" == "app" -o "$HOSTPREFIX" == "scripts" -o "$HOSTPREFIX" == "mon" -o "$HOSTPREFIX" == "db-fio" -o "$HOSTPREFIX" == "hadoop" -o "$HOSTPREFIX" == "logging" ] ; then
  echo "Host Prefix: $HOSTPREFIX"
else
  echo "error: Unknown host prefix: $HOSTPREFIX"
  Usage
fi


# Run sysync on specified target hosts
for (( i=$START ; i<=$END ; i++ )) ; do 

  /home/scripts/sysync_target_host.sh $HOSTPREFIX-$i commit > /dev/null 2>&1
  
  if [ $? -ne 0 ] ; then 
    echo $HOSTPREFIX-$i failed
  else
    echo $HOSTPREFIX-$i succeeded
  fi
done


