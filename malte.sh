#!/bin/bash

cd /home/git/projop
PKGS_LIST=/home/git/projop/pkgs-list.txt
echo "UPDATE STARTED:: " >/var/log/projop2git/projop.log
echo `date` >>/home/git/projop/update.log 
for pkg in `cat $PKGS_LIST`; do
        echo "$pkg" >>/var/log/projop2git/projop.log
        ./github-update $pkg >>/var/log/projop2git/projop.log 2>&1
done