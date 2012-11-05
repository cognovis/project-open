# /packages/intranet-reporting/www/xmlhttp-object-options-custom.tcl
#
# Copyright (C) 2012 ]project-open[
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

ad_page_contract {
    Returns a key-value list of combo elements 
    in either JSON or XML format that can be used to update 
    an arbitrary form combo

    Page is WIP. Support for new combinations will be added
    on user request. 
 
    @author klaus.hofeditz@project-open.com
} {
    { object_type }
    { source_form_element_name } 
    { source_form_element_value:integer }
    { auto_login "" }
}

# -------------------------------------
# Security & Defaults 
# -------------------------------------

# ToDo: Check usefullness of [im_rest_authenticate]
set current_user_id [ad_maybe_redirect_for_registration]

# -------------------------------------
# Body 
# -------------------------------------

switch $object_type {
	im_project { 
		if { "customer_id" == $source_form_element_name } {
			if { [im_permission $current_user_id "view_projects_all"] } {
				set option_list [im_project_options \
					    -include_empty 1 \
					    -include_empty_name "" \
					    -include_project_ids 1 \
					    -exclude_subprojects_p 0 \
					    -exclude_tasks_p 1 \
					    -company_id $source_form_element_value \
					]
 
			} else {
                        	set option_list [im_project_options \
					    -include_empty 1 \
					    -include_empty_name "" \
                                            -include_project_ids 1 \
                                            -exclude_subprojects_p 0 \
                                            -exclude_tasks_p 1 \
					    -member_user_id $current_user_id \
					    -company_id $source_form_element_value \
                                        ]
			}
		}
	}
        default {
		# not yet defined, return error
		# return [im_rest_error -format $format -http_status 404 -message " ('$auth_method')."]
        }
}

set result "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
append result "<dropdown>\n"
set ctr 0 
foreach { key_value } $option_list {
	append result "<select_item>\n"
	append result "<title>[lindex $key_value 0]</title>\n"
	append result "<values><value>[lindex $key_value 1]</value></values>\n"
	append result "</select_item>\n"
        incr ctr
}

if { 0 == $ctr } {
    append result "<select_item>\n"
    append result "<title>[lang::message::lookup "" intranet-core.NoProjectsFound "No Projects found"]</title>\n"
    append result "<values><value></value></values>\n"
    append result "</select_item>\n"    
}
append result "</dropdown>"
doc_return 200 "xml" $result
