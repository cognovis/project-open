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
}

# ---------------------------------------------------------------
# Constants
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set base_url "/intranet-sysconfig/segment"

# Define Wizard params
set pages [list index sector deptcomp features orgsize prodtest confirm]


# Frequent used HTML snippets
set bg "/intranet/images/girlongrass.600x400.jpg"
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
	append advance_component "<input type=checkbox name=asdf checked disabled> $p_l10n=$v<br>\n"
    } else {
	set v ""
	append advance_component "<input type=checkbox name=asdf disabled> $p_l10n=$v <br>\n"
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
# See what variables to export
# (all, except the one defined in this page)
# ---------------------------------------------------------------

set export_vars [list]
foreach p $pages {
    if {$p == $page} { continue }
    lappend export_vars $p
}

set cmd [linsert $export_vars 0 "export_form_vars"]
set export_vars [eval $cmd]



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
