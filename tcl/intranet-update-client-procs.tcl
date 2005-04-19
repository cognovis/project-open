# /packages/intranet-update-client/tcl/intranet-update-client-procs.tcl

ad_library {
    Project/Open Automatic Software Updates
    @author frank.bergmann@project-open.com
    @creation-date 27 April 2005
}


#ad_proc -public im_update_client_package_id {} {
#    Returns the package id of the intranet-update-client package
#} {
#    return [util_memoize "im_update_client_package_id_helper"]
#}

ad_proc -private im_update_client_package_id {} {
    return [db_string im_package_update_client_id {
        select package_id from apm_packages
        where package_key = 'intranet-update-client'
    } -default 0]
}


ad_proc im_update_component { } {
    Stub for some future components...
} {
    return ""
}
