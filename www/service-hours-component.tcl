# /packages/intranet-sla-management/www/service-hours-component.tcl
#
# Copyright (c) 2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.
#
# Shows business hours for the specified SLA.

# ---------------------------------------------------------------
# Variables
# ---------------------------------------------------------------

#    { project_id:integer "" }
#    return_url 

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
if {"" == $return_url} { set return_url [ad_conn url] }
set page_title [lang::message::lookup "" intranet-sla-management.Service_Hours "Service Hours"]
set context_bar [im_context_bar $page_title]
set context ""
set sla_id $project_id

im_project_permissions $current_user_id $project_id sla_view sla_read sla_write sla_admin
# sla_read checked in the .adp file

# ---------------------------------------------------------------
# List of weekdays
set dow_list [list]
lappend dow_list [lang::message::lookup "" intranet-core.Sunday Sunday]
lappend dow_list [lang::message::lookup "" intranet-core.Monday Monday]
lappend dow_list [lang::message::lookup "" intranet-core.Tuesday Tuesday]
lappend dow_list [lang::message::lookup "" intranet-core.Wednesday Wednesday]
lappend dow_list [lang::message::lookup "" intranet-core.Thursday Thursday]
lappend dow_list [lang::message::lookup "" intranet-core.Friday Friday]
lappend dow_list [lang::message::lookup "" intranet-core.Saturday Saturday]


# Create the header for the table
multirow create hours hour
for {set h 0} {$h < 24} {incr h} {
    set h_string $h
    if {[string length $h_string] < 2} { set h_string "0$h_string" }
    multirow append hours $h_string
}

# Create the table body
set body_html ""
for {set day 0} {$day < 7} {incr day} {

    set line_html "<tr>\n"
    append line_html "<td>[lindex $dow_list $day]</td>\n"
    for {set h 0} {$h < 24} {incr h} {
	set idx [expr $day*100 + $h]
	set checked "checked"
	append line_html "<td align=center><input type=checkbox name=hours.$idx $checked></td>\n"
    }
    append line_html "</tr>\n"
    append body_html $line_html
}
