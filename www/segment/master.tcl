# /packages/intranet-sysconfig/www/master.tcl
#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    This is the master file that deals with functions
    common to all wizard parges
} {
    sector:optional 
    orgsize:optional
    features:optional
    deptcomp:optional
    prodtest:optional

    name:optional
    { name_name:optional "Tigerpond Inc." }
    { name_email:optional sysadmin@tigerpond.com }

    logo:optional
    logo_file:optional
    { logo_url:optional http://www.project-open.com/ }

    profiles:optional
    profiles_array:array,optional
}

# ---------------------------------------------------------------
# Constants
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]"
    return
}

set base_url "/intranet-sysconfig/segment"

# Define Wizard params
set pages [list index sector deptcomp features orgsize name logo profiles confirm]
set vars $pages
lappend vars name_name name_email logo_file logo_url profiles_array:multiple

# Frequent used HTML snippets
set bg ""
set po "<span class=brandsec>&\\#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&\\#91;</span>"

# ---------------------------------------------------------------
# Advance Component
# ---------------------------------------------------------------

set advance_component ""
foreach p $pages {

    if {"index" == $p} { continue }
    if {"confirm" == $p} { continue }
    set p_l10n [lang::message::lookup "" "intranet-sysconfig.Page_$p" $p]

    if {[exists_and_not_null $p]} {
	set v [expr "\$$p"]
	append advance_component "<input type=checkbox name=asdf checked disabled> $p_l10n<br>\n"
    } else {
	set v ""
	append advance_component "<input type=checkbox name=asdf disabled> $p_l10n<br>\n"
    }
}

# ---------------------------------------------------------------
# Calculate the Prev & Next buttons
# ---------------------------------------------------------------

set url [ad_conn url]
set url_pieces [split $url "/"]
set url_last_piece [lindex $url_pieces [expr [llength $url_pieces]-1]]
set page $url_last_piece

# ---------------------------------------------------------------
# Handle logo file upload
# ---------------------------------------------------------------

set tmp_filename [ns_queryget logo_file.tmpfile]
if {![empty_string_p $tmp_filename] 
} { 
    file copy -force $tmp_filename [acs_root_dir]/www/sysconf-logo.tmp
}

# ---------------------------------------------------------------
# See what variables to export
# (all, except the one defined in this page)
# ---------------------------------------------------------------

set export_vars [list]
foreach p $vars {
    set p_first_piece [lindex [split $p "_"] 0]

    if {$p_first_piece == $page} { continue }
    lappend export_vars $p
}

set export_vars [eval "export_vars -form { $export_vars }"]

# ---------------------------------------------------------------
# Setup << Pref & Next >> Buttons
# ---------------------------------------------------------------

set index [lsearch $pages $page]

# Deal with Exceptions
switch $page {
    index {
	set prev ""
    }
}

set prev_page [lindex $pages [expr $index-1]]
set next_page [lindex $pages [expr $index+1]]

set prev_link "<input type=button class=button name=prev value='&lt;&lt; Prev'
	onClick=\"window.document.wizard.action='$prev_page'; submit();\" 
	title='&lt;&lt; Prev' alt='&lt;&lt; Prev'
>"
set next_link "<input type=button class=button name=next value='Next &gt;&gt;'
	onClick=\"window.document.wizard.action='$next_page'; submit();\" 
	title='Next &gt;&gt;' alt='Next &gt;&gt;'
>"


if {"" == $prev_page} { set prev_link "" }
if {"" == $next_page} { set next_link "" }

set navbar "
	<table cellspacing=0 cellpadding=4 border=0>
	<tr><td>$prev_link</td><td>$next_link</td></tr>
	</table>
"
