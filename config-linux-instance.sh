#!/bin/bash
logfile=/tmp/setup.log
echo "START" > logfile
exec > $logfile 2>&1  # Log stdout and std to logfile in /tmp

# Script to configure typical Linux host after launchtime

# Check for root
[ "$(id -u)" -ne 0 ] && echo "Incorrect Permissions - Run this script as root" && exit 1

TIMESTAMP=$(date)

echo; echo "== Install Updates"
#yum -y update  #<--Disabled this for POC so that any vulns are not patched at first boot
q
echo; echo "== Turn on Process Accounting"
chkconfig psacct on

echo; echo "== Setup AWS Inspector"
cd /tmp
wget https://d1wk0tztpsntt1.cloudfront.net/linux/latest/install
bash install

echo; echo "== SCRIPT COMPLETE"
echo; echo "== $0 has completed"
