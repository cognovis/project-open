ad_page_contract {
    Bug listing page.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 2002-03-20
    @cvs-id $Id$
} [bug_tracker::get_page_variables]

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

#####
#
# Get bug list
#
#####


# TODO: Get /com/* URLs working again
# TODO: Other important suggestions from threads, etc.
# TODO: Bulk actions (set fix for version, reassign, etc.)


bug_tracker::bug::get_list

bug_tracker::bug::get_multirow


# -------------------------------------------
# Format the NavBar

# Compile and execute the formtemplate if advanced filtering is enabled.
eval [template::adp_compile -string {<listfilters name="bugs"></listfilters>}]
set filter_html $__adp_output

# Left Navbar is the filter/select part of the left bar
set left_navbar_html "
	<div class='filter-block'>
        	<div class='filter-title'>
	           #intranet-core.Filter_Projects#
        	</div>
            	$filter_html
      	</div>
      <hr/>
"
