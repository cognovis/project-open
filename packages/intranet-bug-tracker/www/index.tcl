ad_page_contract {
    Bug listing page.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 2002-03-20
    @cvs-id $Id: index.tcl,v 1.3 2010/09/08 15:09:26 cvs Exp $
} [bug_tracker::get_page_variables]

ns_log Notice "page_variables [bug_tracker::get_page_variables]"
set page_title [ad_conn instance_name]
set context [list]
set admin_p [permission::permission_p -object_id [ad_conn package_id] -privilege admin]
bug_tracker::get_pretty_names -array pretty_names

if { [llength [bug_tracker::components_get_options]] == 0 } {
    ad_return_template "no-components"
    return
}

if { ![bug_tracker::bugs_exist_p] } {
    ad_return_template "no-bugs"
    return
}

set project_id [ad_conn package_id]


bug_tracker::bug::get_list

bug_tracker::bug::get_multirow


