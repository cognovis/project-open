# /packages/intranet-reporting-finance/tcl/intranet-reporting-finance-procs.tcl
#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Finance Reporting Component Library
    @author frank.bergmann@project-open.com
}

# -------------------------------------------------------
# Package Procs
# -------------------------------------------------------

ad_proc -public im_package_reporting_finance_id {} {
    Returns the package id of the intranet-reporting-finance module
} {
    return [util_memoize "im_package_reporting_finance_id_helper"]
}

ad_proc -private im_package_reporting_finance_id_helper {} {
    return [db_string im_package_core_id {
        select package_id from apm_packages
        where package_key = 'intranet-reporting-finance'
    } -default 0]
}

