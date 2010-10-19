# /packages/acs-lang/tcl/apm-callback-procs.tcl

ad_library {

    APM callbacks library

    @creation-date August 2009
    @author  Emmanuelle Raffenne (eraffenne@gmail.com)
    @cvs-id $Id: apm-callback-procs.tcl,v 1.1 2010/10/19 21:21:12 po34demo Exp $

}

namespace eval lang {}
namespace eval lang::apm {}

ad_proc -private lang::apm::after_install {
} {
    After install callback
} {
}

ad_proc -private lang::apm::after_upgrade {
    {-from_version_name:required}
    {-to_version_name:required}
} {
    After upgrade callback for acs-lang
} {
    apm_upgrade_logic \
        -from_version_name $from_version_name \
        -to_version_name $to_version_name \
        -spec {
        }
}
