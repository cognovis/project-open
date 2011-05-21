# packages/extjs/tcl/intranet-extjs-procs.tcl

## Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
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

ad_library {
    
    Wrapper procedures to make use of extjs in ]project-open[
    
    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
    @creation-date 2011-03-29
    @cvs-id $Id$
}

namespace eval intranet_extjs {}
namespace eval intranet_extjs::combobox {}

ad_proc -public intranet_extjs::combobox::categories {
    {-category_type ""}
    {-parent_id ""}
    {-combo_name:required}
    {-form_name:required}
} {
    Generates the combobox code for an ExtJS categories combobox with all the categories of the category type
    in hierarchical order

    @param category_type the CATEGORY Type
    @param combo_name name of the combobox element
    @param form_name name of the form
    @param parent_id Parent Category_id
} {
    if {$parent_id ne ""} {
        set sql "select category_id, category from im_categories c left outer join im_category_hierarchy h on (c.category_id = h.child_id) where parent_id = $parent_id"
    } else {
        set sql "select category_id, category from im_categories where category_type = '$category_type'"
    }
    set benefit_category_combobox [extjs::RowEditor::ComboBox -combo_name "$combo_name" -form_name "$form_name" -sql $sql]
}

ad_proc -public intranet_extjs::json {
    {-sql:required}
    {-view_name:required}
    {-variable_set ""}
} {
    Takes a SQL statement and a view_name to create a JSON for each column in the view with all the rows from the SQL
    
    @param sql A SQL statement which is used to get each row of the spreadsheet
    @param view_name Name of the dynfield view for which to generate the Spreadsheet
    @param variable_set ns_set of variables we need locally.
} {

    # Get the "view" (=list of columns to show)
    set view_id [util_memoize [list db_string get_view_id "select view_id from im_views where view_name = '$view_name'" -default 0]]
    if {0 == $view_id} {
        ad_return_error Error "intranet_openoffice::spreadsheet: We didn't find view_name=$view_name"
    }

    if {$variable_set ne ""} {
        ad_ns_set_to_tcl_vars -duplicates ignore $variable_set
    }
    
    set variables [db_list get_variables "
	select	variable_name
	from	im_view_columns
	where	view_id=:view_id
		and group_id is null
        and variable_name is not null
	order by sort_order
    "]

    # No create the single rows for each Object
    db_foreach elements $sql {
        foreach variable $variables {
            lappend json_list $variable
            lappend json_list [set $variable]
        }
    }
    # Make sure we have no " " " unescaped
    regsub -all "\"" $json_list {\"} json_list
    return [util::json::gen [util::json::object::create $json_list]]
}


ad_proc -public -callback im_projects_index_filter -impl extjs_json {
    {-form_id:required}
} {
    Add the filter for JSON to the view_type
} {
    uplevel {
        set view_type_options [concat $view_type_options {{JSON json}}]
    }
}


ad_proc -public -callback im_projects_index_before_render -impl extjs_json {
    {-view_name:required}
    {-view_type:required}
    {-sql:required}
    {-table_header ""}
    {-variable_set ""}
} {
    Depending on the view_type return a json file
} {
 
    # Only execute for view types which are supported
    if {[lsearch [list json] $view_type] > -1} {
        ns_return 200 text/text [intranet_extjs::json -sql $sql -view_name $view_name -variable_set $variable_set]
        ad_script_abort
    }
}

ad_proc -public -callback im_timesheet_tasks_index_filter -impl extjs_json {
    {-form_id:required}
} {
    Add the filter for JSON to the view_type
} {
    uplevel {
        set view_type_options [concat $view_type_options {{JSON json}}]
    }
}

ad_proc -public -callback im_timesheet_task_list_before_render -impl extjs_json {
    {-view_name:required}
    {-view_type:required}
    {-sql:required}
    {-table_header ""}
} {
    Return JSON code for use as a Datastore
} {
 
    # Only execute for view types which are supported
    if {$view_type ne "json"} {
        return
    }
    
    # We ignore view_name and table_header as we don't bother with
    # this. We only want to get the variables into json :-).
    db_multirow task_list_multirow task_list_sql $sql {

        # Perform the following steps in addition to calculating the multirow:
        # The list of all projects
        set all_projects_hash($child_project_id) 1
        # The list of projects that have a sub-project
        set parents_hash($child_parent_id) 1
    }

    # Store results in hash array for faster join
    # Only store positive "closed" branches in the hash to save space+time.
    # Determine the sub-projects that are also closed.
    set user_id [ad_get_user_id]
    set oc_sub_sql "
	select	child.project_id as child_id
	from	im_projects child,
		im_projects parent
	where	parent.project_id in (
			select	ohs.object_id
			from	im_biz_object_tree_status ohs
			where	ohs.open_p = 'c' and
				ohs.user_id = :user_id and
				ohs.page_url = 'default' and
				ohs.object_id in (
					select	child_project_id
					from	($sql) p
				)
			) and
		child.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey)
    "
    db_foreach oc_sub $oc_sub_sql {
        set closed_projects_hash($child_id) 1
    }

    # Calculate the list of leaf projects
    set all_projects_list [array names all_projects_hash]
    set parents_list [array names parents_hash]
    set leafs_list [set_difference $all_projects_list $parents_list]
    foreach leaf_id $leafs_list { set leafs_hash($leaf_id) 1 }

    set parents [list]
    template::multirow foreach task_list_multirow {

        # Here we should care about the view !!
        set variable_list($child_project_id) [list task $task_name duration $planned_units_subtotal user $project_lead]
        if {[info exists leafs_hash($child_project_id)]} {
            # This is a leave, set the json object
            set leaf_list [list iconCls "task" leaf "true"]
            set json_list  [concat $variable_list($child_project_id) $leaf_list]
            regsub -all "\"" $json_list {\"} json_list
            set json_object($child_project_id) [util::json::object::create $json_list]
        } else {
            # create a parents list which is buttom up, so we can go
            # through this list and correctly build the json arrays
            set parents [concat $child_project_id $parents]
        }
        if {$child_parent_id ne ""} {
            # Add the leave to the parent list
            lappend children($child_parent_id) $child_project_id
        }
    }

    foreach parent $parents {
        # build the json array

        # Build the children
        set json_objects [list]
        foreach child $children($parent) {
            lappend json_objects $json_object($child)
        }
        set json_array(children) [util::json::array::create $json_objects]
        
        # build the own entry
        set json_array(inconCls) "task-folder"
        if {![info exists closed_projects_hash($parent)]} {
            set json_array(expanded) "true"
        }
        set json_list  [concat $variable_list($parent) [array get json_array]]
        set json_object($parent) [util::json::object::create $json_list]
        array unset json_array

        # Set the top_id to the parent so we can figure out what is
        # actually the last and therefore topmost json_object
        set top_id $parent
    }
    
    ns_return 200 text/text [util::json::gen $json_object($top_id)]
    ad_script_abort
}

