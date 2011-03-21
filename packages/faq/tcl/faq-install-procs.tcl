ad_library {
    FAQ install callbacks

    @creation-date 2004-04-01
    @author Jeff Davis davis@xarg.net
    @cvs-id $Id: faq-install-procs.tcl,v 1.2 2004/05/19 20:07:02 rocaelh Exp $
}

namespace eval faq::install {}

ad_proc -private faq::install::package_install {} { 
    package install callback
} {
    faq::sc::register_implementations
    faq::apm_callback::package_install
}

ad_proc -private faq::install::package_uninstall {} { 
    package uninstall callback
} {
    faq::sc::unregister_implementations
    faq::apm_callback::package_uninstall
}

ad_proc -private faq::install::package_upgrade {
    {-from_version_name:required}
    {-to_version_name:required}
} {
    Package before-upgrade callback
} {
    apm_upgrade_logic \
        -from_version_name $from_version_name \
        -to_version_name $to_version_name \
        -spec {
            5.2.0d1 5.2.0d2 {
                # need to install the faq callbacks
                faq::sc::register_faq_fts_impl
                faq::sc::register_faq_q_and_a_fts_impl
                faq::apm_callback::package_install
            }
        }
}
