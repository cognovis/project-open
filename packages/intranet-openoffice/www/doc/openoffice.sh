#!/bin/bash                                                                                                                                                 
# openoffice.org  headless server script                                                                                                                    
#                                                                                                                                                           
# chkconfig: 2345 80 30                                                                                                                                     
# description: headless openoffice server script                                                                                                            
# processname: openoffice                                                                                                                                   
#                                                                                                                                                           
# Author: Vic Vijayakumar                                                                                                                                   
#                                                                                                                                                           

OOo_HOME=/usr/lib/openoffice/
SOFFICE_PATH=$OOo_HOME/program/soffice
PIDFILE=$OOo_HOME/openoffice-server.pid
JOD_HOME=/usr/lib/jodconverter
JAVA_HOME=/usr/lib/jvm/java-6-sun/jre
case "$1" in
    start)
    if [ -f $PIDFILE ]; then
      echo "OpenOffice headless server has already started."
      exit
    fi
      echo "Starting OpenOffice headless server"
      $SOFFICE_PATH -headless -accept="socket,host=127.0.0.1,port=8100;urp" -nofirststartwizard & > /dev/null 2>&1
      $JOD_HOME/bin/startup.sh & > /dev/null 2>&1
      touch $PIDFILE
    ;;
    stop)
    if [ -f $PIDFILE ]; then
        echo "Stopping OpenOffice headless server."
        killall -9 soffice
        killall -9 soffice.bin
        $JOD_HOME/bin/catalina.sh stop > /dev/null 2>&1
        rm -f $PIDFILE
        exit
    fi
      echo "Openoffice headless server is not running, foo."
      exit
      ;;
    *)
    echo "Usage: $0 {start|stop}"
    exit 1
esac
exit 0