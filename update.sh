#!/bin/bash

cd /home/git/project-open
/usr/bin/git checkout commercial
PKGS_LIST=/home/git/projop2git/config/pkgs-commercial.txt
echo "UPDATE STARTED:: " >/var/log/projop2git/projop-commercial.log
echo `date` >>/var/log/projop2git/projop-commercial.log
for pkg in `cat $PKGS_LIST`; do
        echo "$pkg" >>/var/log/projop2git/projop-commercial.log
        ./github-update $pkg >>/var/log/projop2git/projop-commercial.log 2>&1
done
/usr/bin/git push origin commercial