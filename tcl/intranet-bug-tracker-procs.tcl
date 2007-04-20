# /packages/intranet-bug-tracker/tcl/intranet-bug-tracker.tcl
#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    This Bug-Tracker integration aloows to associate ]po[ tasks
    with OpenACS Bug-Tracker tickets, allowing for the best of
    the two worlds
	- Developer friendly maintenance of product bugs
	- Multiple "Products"
	- A customer wizard to create new bugs and to check his
	  own bugs, but without being able to see the bugs of
	  other customers
	- Integration with Timesheet Billing using the billing
	  wizard.

    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# Constants
# ----------------------------------------------------------------------

ad_proc -public im_project_type_bt_container { } { return 4300 }
ad_proc -public im_project_type_bt_task { } { return 4305 }



# ----------------------------------------------------------------------
# Package ID
# ----------------------------------------------------------------------


ad_proc -public im_package_bug_tracker_id {} {
    Returns the package id of the intranet-bug-tracker module
} {
    return [util_memoize "im_package_bug_tracker_id_helper"]
}

ad_proc -private im_package_bug_tracker_id_helper {} {
    return [db_string im_package_core_id {
        select package_id from apm_packages
        where package_key = 'intranet-bug-tracker'
    } -default 0]
}


# ----------------------------------------------------------------------
# Options & Selects
# ----------------------------------------------------------------------

ad_proc -public im_bt_project_options { 
    {-include_empty_p 0}
} {
    Get a list of "BT Container Projects" for the current user.
} {
    set user_id [ad_get_user_id]
    set options [db_list_of_lists project_options "
	select
		p.project_id,
		p.project_name,
                pp.project_name AS parent_name
	from
		im_projects p LEFT JOIN im_projects pp ON (
                  p.parent_id = pp.project_id
                ),
		acs_rels r
	where
		p.project_type_id = [im_project_type_bt_container]
		and r.object_id_one = p.project_id
		and r.object_id_two = :user_id
    "]
    if {$include_empty_p} { set options [linsert $options 0 { "" "" }] }
    return $options
}

ad_proc -public im_bt_project_options_form { 
   {-include_empty:boolean 0}
} {
    Get a list of "BT Container Projects" for the current user.
} {
    set user_id [ad_get_user_id]
    set options [db_list_of_lists project_options "
	select
            case when pp.project_name is null 
                then 
                    p.project_name
                else
		    pp.project_name || ' : ' ||
                    p.project_name
                end  AS name,
		p.project_id
	from
		im_projects p LEFT JOIN im_projects pp ON (
                  p.parent_id = pp.project_id
                ),
		acs_rels r
	where
		p.project_type_id = [im_project_type_bt_container]
		and r.object_id_one = p.project_id
		and r.object_id_two = :user_id
        order by 
                name
    "]
    if {$include_empty_p} { set options [linsert $options 0 { "" "" }] }
    return $options
}

ad_proc -public im_bt_generic_select { 
    {-include_empty_p 0}
    { -options ""}
    name
    default
} {
    Get a list of "BT Container Projects" for the current user.
} {
    set result "<select name=\"$name\">\n"
    foreach option $options {
	set id [lindex $option 0]
	set name [lindex $option 1]
	set parent_name [lindex $option 2]
	if {$default == $id} { set selected "" } else { set selected "selected" }
	append result "<option value=\"$id\" $selected>$parent_name : $name</option>\n"
    }
    append result "</select>\n"
    return $result
}

ad_proc -public im_bt_project_select { 
    {-include_empty_p 0}
    name
    default
} {
    Get a list of "BT Container Projects" for the current user.
} {
    set options [im_bt_project_options -include_empty_p $include_empty_p]
    return [im_bt_generic_select -include_empty_p $include_empty_p -options $options $name $default]
}



# ----------------------------------------------------------------------
# Components
# ----------------------------------------------------------------------

ad_proc -public im_bug_tracker_container_component {

} {
    Returns a HTML widget for a BT "Container Project" to allow
    the PM to set BT parameters like the BT project (better: "Product")
    and the current version, so that the customer doesn't need to set
    all these variables.
} {
    set action_url "/bug-tracker/bug-add"
    set return_url [im_url_with_query]
    set options [im_bt_project_options]
    if {[llength $options] > 0} {
	set project_html [im_bt_generic_select -options $options bug_container_project_id ""]
	set button_text [lang::message::lookup "" intranet-bug-tracker.New_Issue "New Issue"]
	set button_html "<input type=submit value=\"$button_text\">"
    } else {
	# Just return an empty string in order to disable this component
	return ""
	set project_html [lang::message::lookup "" intranet-bug-tracker.You_are_not_a_member_of_any_maintenance_projects "You are not a member of any maintenance project"]
	set button_html ""
    }

    set html "
	<table cellspacing=1 cellpadding=1>
	<form action=\"$action_url\" method=GET>
        [export_form_vars return_url]
	<tr class=rowtitle>
	  <td class=rowtitle colspan=2>
	    [lang::message::lookup "" intranet-bug-tracker.Create_a_New_Issue "Create a New Issue"]
	  </td>
	</tr>
	<tr>
	  <td class=form-label>
	    [lang::message::lookup "" intranet-bug-tracker.Project "Project"] &nbsp;
	  </td>
	  <td class=form-widget>
	    $project_html
	  </td>
	</tr>
	<tr>
	  <td class=form-label></td>
	  <td class=form-widget>$button_html</td>
	</tr>
	</form>
	</table>
    "
    return $html
}


ad_proc -public im_bug_tracker_list_component {
    project_id
} {
    shows a list of bugs in the current project
} {
    if {![im_project_has_type $project_id "Bug Tracker Container"]} {
        return ""
    }

    set html ""

    db_multirow bug_list bug_list "
	select
		bug_number,summary
	from
		im_projects parent,
		im_projects children,
                bt_bugs
	where
		children.project_type_id not in ([im_project_type_task])
		and children.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey)
		and parent.project_id = [im_project_super_project_id $project_id]
                and bug_container_project_id=children.project_id
	order by bug_number desc
            "
    
   template::list::create \
	-name bug_list \
	-key bug_id \
	-pass_properties { return_url } \
	-elements {
	    bug_number {
		label "bug\#"
		link_url_eval { 
			[return "/bug-tracker/bug?[export_vars -url { bug_number return_url  } ]" ]
		}
	    } 
	    summary {
		label "Summary"
	    }
	} 
    
    append html [template::list::render -name bug_list]
    
    return $html
}

