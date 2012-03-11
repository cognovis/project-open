# 
#
# Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see
# <http://www.gnu.org/licenses/>.
#
 
ad_page_contract {
    
    Create the tasks and the quote
    
    @author <yourname> (<your email>)
    @creation-date 2012-03-11
    @cvs-id $Id$
} {
    project_id:integer
} -properties {
} -validate {
} -errors {
}

set user_id [ad_conn user_id]
if {![im_permission $user_id view_trans_proj_detail]} { return "" }
im_project_permissions $user_id $project_id view read write admin
if {!$write} { return "" }

set default_uom [parameter::get_from_package_key -package_key intranet-trans-invoices -parameter "DefaultPriceListUomID" -default 324]

# Get some basic information about our current project
db_1row project_info "
	select	project_type_id,company_id
	from	im_projects
	where	project_id = :project_id
    "

ad_form -name tasks -action /intranet-translation/projects/new-2 -form {
    {uom_id:integer(im_category_tree)
	{label "UOM"}
	{value $default_uom}
	{custom {category_type "Intranet UoM" translate_p 1}}
    }
    {project_id:integer(hidden)
	{value $project_id}
    }
}

# Get the sorted list of files in the directory
set files [lsort [im_filestorage_find_files $project_id]]
set project_path [im_filestorage_project_path $project_id]
set org_paths [split $project_path "/"]
set org_paths_len [llength $org_paths]
set start_index $org_paths_len

set file_ctr 0
foreach file $files {

    incr file_ctr
    # Get the basic information about a file
    ns_log Notice "file=$file"
    set file_paths [split $file "/"]
    set file_paths_len [llength $file_paths]
    set body_index [expr $file_paths_len - 1]
    set file_body [lindex $file_paths $body_index]
    
    # The first folder of the project - contains access perms
    set top_folder [lindex $file_paths $start_index]
    ns_log Notice "top_folder=$top_folder"
    
    # Check if it is the toplevel directory
    if {[string equal $file $project_path]} { 
	# Skip the path itself
	continue 
    }
    
    # determine the part of the filename _after_ the base path
    set end_path ""
    for {set i [expr $start_index+1]} {$i < $file_paths_len} {incr i} {
	append end_path [lindex $file_paths $i]
	if {$i < [expr $file_paths_len - 1]} { append end_path "/" }
    }
    
    ad_form -extend -name tasks -form {
	{file_name_${file_ctr}:text(hidden)
	    {value $end_path}
	}
	{file_units_${file_ctr}:integer(text)
	    {label "$end_path"}
	    {help_text "Units for $end_path"}
	}
    }
}

if {"" == $files} {
    # We only provide tasks
    set task_ctr 0
    while {$task_ctr < 5} {
	incr task_ctr
	ad_form -extend -name tasks -form {
	    {task_name_${task_ctr}:text(text),optional
		{label "Task $task_ctr"}
	    }
	    {task_units_${task_ctr}:float(text),optional
		{label "Units $task_ctr"}
		{help_text "Please enter task and units"}
	    }
	}
    }
    ad_form -extend -name tasks -form {
	{task_ctr:text(hidden)
	    {value $task_ctr}
	}
    } -on_submit {
	# Create the tasks for each file
	set i 1   
	while {$i <= $task_ctr} {
	    set task_name [set task_name_$i]
	    set task_units [set task_units_$i]	
	    set target_language_ids [im_target_language_ids $project_id]
	    if {"" != $task_name} {
		im_task_insert $project_id [ns_urldecode $task_name] $task_name $task_units $uom_id $project_type_id $target_language_ids
	    }
	    incr i
	}
    }

} else {

    # Create the tasks for each file
    set i 1   
    while {$i <= $file_ctr} {
	set task_filename [set file_name_$i]
	set task_units_file [set file_units_$i]	
	set target_language_ids [im_target_language_ids $project_id]
	im_task_insert $project_id $task_filename $task_filename $task_units_file $uom_id $project_type_id $target_language_ids
	incr i
    }
}

ad_form -extend -name tasks -after_submit {
    im_trans_task_project_advance $project_id
    
    set task_ids [db_list task_ids "select task_id from im_trans_tasks where project_id = :project_id"]
    set invoice_currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]
    set target_cost_type_id [im_cost_type_quote]

    set return_url [export_vars -base "/intranet-trans-invoices/invoices/new-3.tcl" {invoice_currency company_id target_cost_type_id}]
    foreach task_id $task_ids {
	append return_url "&include_task=$task_id"
    }
    ad_returnredirect $return_url
}


