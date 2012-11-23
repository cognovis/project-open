#!/bin/bash

cd /home/git/project-open-orig
PKGS_LIST=/home/git/projop2git/config/pkgs-list.txt
echo "UPDATE STARTED:: " >/var/log/projop2git/projop.log
echo `date` >>/var/log/projop2git/projop.log
for pkg in `cat $PKGS_LIST`; do
        echo "$pkg" >>/var/log/projop2git/projop.log
        ./github-update $pkg >>/var/log/projop2git/projop.log 2>&1
done
/usr/bin/git push origin master