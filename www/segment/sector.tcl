# /packages/intranet-sysconfig/www/sector/sector.tcl
#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {

} {

}


# ---------------------------------------------------------------
# Frequently used variables
# ---------------------------------------------------------------

set bg "/intranet/images/girlongrass.600x400.jpg"
set po "<span class=brandsec>&\#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&\#91;</span>"

set sector ""
set vars [ad_conn form]
for { set i 0 } { $i < [ns_set size $vars] } { incr i } {
    set key [ns_set key $vars $i]
    set val [ns_set value $vars $i]

    if {"sector" == $key} { set sector $val }
}
