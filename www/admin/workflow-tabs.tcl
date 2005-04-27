#
# Tabs for workflow-page
#
# Input:
#   tab
#   workflow_key
#
# Data sources:
#   tabs:multirow name url
#
# Author: Lars Pind (lars@pinds.com)
# Creation-date: Feb 26, 2001
# Cvs-id: $Id$
#

template::multirow create tabs name key url 
foreach loop_tab {
    { Home home } 
    { Transitions process } 
    { Attributes attributes } 
    { Roles roles } 
    { Panels panels }
    { Assignments assignments } 
} {
    template::multirow append tabs [lindex $loop_tab 0] [lindex $loop_tab 1] "workflow?[export_vars -url {workflow_key {tab {[lindex $loop_tab 1]}}}]"
}

#   { Timing timing } 
#   { Actions actions } 

