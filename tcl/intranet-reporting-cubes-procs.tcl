# /packages/intranet-reporting-cubes/tcl/intranet-reporting-cubes-procs.tcl
#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Cubes Reporting Component Library
    @author frank.bergmann@project-open.com
}

# -------------------------------------------------------
# Package Procs
# -------------------------------------------------------

ad_proc -public im_package_reporting_cubes_id {} {
    Returns the package id of the intranet-reporting-cubes module
} {
    return [util_memoize "im_package_reporting_cubes_id_helper"]
}

ad_proc -private im_package_reporting_cubes_id_helper {} {
    return [db_string im_package_core_id {
        select package_id from apm_packages
        where package_key = 'intranet-reporting-cubes'
    } -default 0]
}

