#!/bin/bash

PKGS_LIST=/home/git/projop2git/config/pkgs-list.txt
echo "UPDATE STARTED:: " >/home/git/projop/update.log 
echo `date` >>/home/git/projop/update.log 
for pkg in `cat $PKGS_LIST`; do
        echo "$pkg" >>/home/git/projop/update.log
        ./github-update $pkg >>/home/git/projop/update.log 2>&1
done