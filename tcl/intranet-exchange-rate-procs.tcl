# /packages/intranet-exchange-rate/tcl/intranet-exchange-rate-procs.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Common procedures for Exchange Rates
    @author frank.bergmann@project-open.com
}

# ----------------------------------------------------------------------
# Exchange Rate from TCL
# ----------------------------------------------------------------------

ad_proc im_exchange_rate { day from_cur to_cur } {
    Returns the exchange rate for a given day
} {
    return [im_exchange_rate_helper $day $from_cur $to_cur]
}


ad_proc im_exchange_rate_helper { day from_cur to_cur } {
    Returns the exchange rate for a given day
} {
    return [db_exec_plsql exchange_rate {}]
}

