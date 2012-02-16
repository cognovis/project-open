# /packages/intranet-sysconfig/www/configurator/config-2.tcl
#
# Copyright (c) 2011 ]project-open[
#
# All rights reserved

ad_page_contract {
    Process Configurator Action page.
    Determines the type of page and branches to the respective parser
    @author frank.bergmann@project-open.com
} {
    { content:allhtml "" }
    { return_url "/intranet-sysconfig/configurator/index" }
    { debug_p 1 }
    { config "pserv" }
}


# ------------------------------------------------------------
# Defaults and Security
# ------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]"
    return
}

set page_title [lang::message::lookup intranet-sysconfig.Parsing_Results "Parsing Results"]

set config [string tolower $config]

# ------------------------------------------------------------
# Parse the input
# ------------------------------------------------------------

# Extract the header line from the file
set separator "\t"
set lines [split $content "\n"]
set rows [llength $lines]
set header [lindex $lines 0]
set headers [split $header $separator]
set cols [llength $headers]
set html ""

if {0 && $debug_p} {
    # Show the parsed results as a table
    append html "<table>\n<tr>\n"
    foreach col $headers {
	append html "<td>$col</td>\n"
    }
    set ctr 0
    foreach line $lines {
	incr ctr
	if {1 == $ctr} { continue }
	append html "<tr>\n"
	foreach l [split $line "\t"] {
	    append html "<td>$l</td>"
	}
	append html "</tr>\n"
    }
    append html "</table>\n"
}



# ------------------------------------------------------------
# Determine which column is the relevant for this configuration
# ------------------------------------------------------------

set conf_col ""
set label_col ""
set ctr 0
foreach h $headers {
    if {$config == [string tolower $h]} { set conf_col $ctr }
    if {"label" == [string tolower $h]} { set label_col $ctr }
    incr ctr
}

if {"" == $conf_col} {
    ad_return_complaint 1 "Didn't find column with title '$config'."
    ad_script_abort
}

if {"" == $label_col} {
    ad_return_complaint 1 "Didn't find column with title 'label'."
    ad_script_abort
}


# ------------------------------------------------------------
#
# ------------------------------------------------------------

# Extract the results
set ctr 0
set ctr_enabled 0
set ctr_disabled 0
foreach line $lines {
    set cells [split $line "\t"]
    set label [lindex $cells $label_col]
    if {"" == $label} { continue }
    set conf [lindex $cells $conf_col]
    set conf_p [string length $conf]

    set menu_id 0
    db_0or1row menu_info "
	select	menu_id,
		enabled_p
	from	im_menus
	where	label = :label
    "
    if {0 == $menu_id} { continue }

#    append html "<li>label=$label, conf_p=$conf_p, menu_id=$menu_id\n"

     if {$conf_p} {
	if {"f" == $enabled_p} {
	    db_dml update "update im_menus set enabled_p = 't' where menu_id = :menu_id"
	    append html "<li>Enabling menu '$label'\n"
	    incr ctr_enabled
	}
     } else {
	if {"t" == $enabled_p} {
	    db_dml update "update im_menus set enabled_p = 'f' where menu_id = :menu_id"
	    append html "<li>Disabling menu '$label'\n"
	    incr ctr_disabled
	}
     }

    incr ctr
}

append html "<li>Enabled $ctr_enabled menus\n"
append html "<li>Disabled $ctr_disabled menus\n"

# Remove all permission related entries in the system cache
im_permission_flush

