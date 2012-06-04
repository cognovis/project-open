#!/bin/bash

. /etc/profile

export ORACLE_BASE=/ora8/m01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/8.1.6
export PATH=$PATH:$ORACLE_HOME/bin
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export ORACLE_SID=ora8
export ORACLE_TERM=vt100
export ORA_NLS33=$ORACLE_HOME/ocommon/nls/admin/data

NLS_LANG=.UTF8
export NLS_LANG

NLS_DATE_FORMAT=YYYY-MM-DD
export NLS_DATE_FORMAT

TZ=GMT
export TZ

exec `dirname $0`/queue-message.pl $*



