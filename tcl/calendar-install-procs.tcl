ad_library {
    Calendar install callbacks

    @creation-date 2004-04-01
    @author Jeff Davis davis@xarg.net
    @cvs-id $Id$
}

namespace eval calendar::install {}

ad_proc -private calendar::install::package_install {} {
    package install callback
} {
    calendar::sc::register_implementations
}

ad_proc -private calendar::install::package_uninstall {} {
    package uninstall callback
} {
    calendar::sc::unregister_implementations
}

ad_proc -private calendar::install::package_upgrade {
    {-from_version_name:required}
    {-to_version_name:required}
} {
    Package before-upgrade callback
} {
    apm_upgrade_logic \
        -from_version_name $from_version_name \
        -to_version_name $to_version_name \
        -spec {
            2.1.0d1 2.1.0d2 {
                # just need to install the cal_item callback
                calendar::sc::register_cal_item_fts_impl
            }
        }
}
