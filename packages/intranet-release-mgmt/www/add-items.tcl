# /packages/intranet-release-mgmt/www/add-items.tcl
#
# Copyright (c) 2003-2007 ]project-open[
# All rights reserved.
#
# Author: frank.bergmann@project-open.com

ad_page_contract {
    Add a new release item to a project

    @author frank.bergmann@project-open.com
} {
    release_project_id:integer
    { filter_project_type_id "" }
    { filter_project_status_id "" }
    { filter_ticket_type_id "" }
    { filter_ticket_status_id "" }
    { filter_release_status_id 1 }
    return_url
}

# -------------------------------------------------------------
# Permissions
#
# The project admin (=> Release Manager) can do everything.
# The managers of the individual Release Items can change 
# _their_ release stati.

set user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-release-mgmt.Release_Items "Release Items"]

im_project_permissions $user_id $release_project_id view read write admin
if {!$write} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient_6]"
    return
}


if {"" == $filter_project_status_id} { set filter_project_status_id [im_project_status_open] }
if {"" == $filter_ticket_status_id} { set filter_ticket_status_id [im_ticket_status_open] }
if {"" != $filter_project_type_id && "" != $filter_ticket_type_id} {
    ad_return_complaint 1 "<b>[lang::message::lookup "" intranet-release-mgmt.Ticket_and_project_selected "
	You have selected both a project type and a ticket type.
    "]</b>"
}

# -------------------------------------------------------------
# Create the list of potential release items to add

set bulk_actions_list [list]
lappend bulk_actions_list "Add Release Items" "add-items-2" "Add new release items"

set elements {
        object_type {
	    label ""
	    display_template {
		@release_items.object_type_html;noquote@
	    }
	}
	project_name {
	    display_col project_name
	    label "Release Item"
	    link_url_eval $release_project_url
	}
        project_chk {
	    label "<input type=\"checkbox\"
			  name=\"_dummy\"
			  onclick=\"acs_ListCheckAll('project_list', this.checked)\"
			  title=\"Check/uncheck all rows\">"
	    display_template {
		@release_items.project_chk;noquote@
	    }
	}
    }

list::create \
    -name release_items \
    -multirow release_items \
    -key release_item \
    -row_pretty_plural $page_title \
    -checkbox_name checkbox \
    -selected_format "normal" \
    -class "list" \
    -main_class "list" \
    -sub_class "narrow" \
    -actions { } \
    -has_checkboxes \
    -bulk_actions $bulk_actions_list \
    -bulk_action_export_vars  { release_project_id return_url } \
    -bulk_action_method GET \
    -elements $elements



# -------------------------------------------------------------
# Prepare the SQL Statement
# -------------------------------------------------------------

set project_release_item_p_sql ""
if {[im_column_exists im_projects release_item_p]} {
    set project_release_item_p_sql "OR p.release_item_p = 't'"
}

if {"" != $filter_project_status_id} {
    lappend criteria "p.project_status_id in ([join [im_sub_categories $filter_project_status_id] ","])"
}
if {"" != $filter_project_type_id} {
    lappend criteria "p.project_type_id in ([join [im_sub_categories $filter_project_type_id] ","])"
}

if {"" != $filter_ticket_status_id} {
    lappend criteria "(t.ticket_status_id is null OR t.ticket_status_id in ([join [im_sub_categories $filter_ticket_status_id] ","]))"
}
if {"" != $filter_ticket_type_id} {
    lappend criteria "t.ticket_type_id in ([join [im_sub_categories $filter_ticket_type_id] ","])"
}

set release_items_sql "
		select	item.project_id
		from	im_projects relp,
			im_projects item,
			acs_rels r,
			im_release_items ri
		where	
			relp.project_type_id in ([join [im_sub_categories [im_project_type_software_release]] ","]) and
			r.object_id_one = relp.project_id and
			r.object_id_two = item.project_id and
			r.rel_id = ri.rel_id
"

switch $filter_release_status_id {
    1 {
	# Not part of a release project yet
	lappend criteria "p.project_id not in ($release_items_sql)"
    }
    2 {
	# Already part of a release project
	lappend criteria "p.project_id in ($release_items_sql)"
    }
}

set where_clause [join $criteria " and\n            "]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}

db_multirow -extend { object_type_html release_project_url release_status_template project_chk } release_items select_release_items "
	select	p.*,
		o.object_type,
		ot.pretty_name,
		ot.object_type_gif
 	from	acs_objects o,
		acs_object_types ot,
		im_projects p
		LEFT OUTER JOIN im_tickets t ON (p.project_id = t.ticket_id)
	where	p.project_id = o.object_id and
		o.object_type = ot.object_type and
		(
			project_type_id in ([join [im_sub_categories -include_disabled_p 1 [im_project_type_software_release_item]] ","])
			$project_release_item_p_sql
		)
		and tree_root_key(p.tree_sortkey) = (select tree_root_key(tree_sortkey) from im_projects where project_id = :release_project_id)
		$where_clause
	order by project_name
" {
    set release_project_url [export_vars -base "/intranet/projects/view?" {project_id return_url}]

    set project_chk "<input type=\"checkbox\"
	name=\"project_id\"
	value=\"$project_id\"
	id=\"project_list,$project_id\">
    "

    set object_type_html [im_gif $object_type_gif $pretty_name]
}


# ---------------------------------------------------------------
# Navbar
# ---------------------------------------------------------------

# Setup the subnavbar
set bind_vars [ns_set create]
ns_set put $bind_vars project_id $release_project_id
set show_context_help_p 0
set parent_menu_id [util_memoize [list db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]]

set menu_label "release_items"
set sub_navbar_html [im_sub_navbar \
    -base_url "/intranet/projects/view?project_id=$release_project_id" \
    $parent_menu_id \
    $bind_vars "" "pagedesriptionbar" $menu_label] 


set release_status_options [list 1 "Not part of a release project yet" 2 "Already part of a release project" 3 "Both"]

set left_navbar_html ""
append left_navbar_html "
      	<div class='filter-block'>
        <div class='filter-title'>
		[lang::message::lookup "" intranet-release-mgmt.Filter_Release_Items "Filter Release Items"]
        </div>
	<form action=add-items method=GET>
	[export_form_vars return_url release_project_id]
	<table>
	<tr>
	<td>[lang::message::lookup "" intranet-release-mgmt.Release_Status "Part of Release Project?"]</td>
	<td>[im_select filter_release_status_id $release_status_options $filter_release_status_id]<br>&nbsp;</td>
	</tr>
	<tr>
	<td>[lang::message::lookup "" intranet-release-mgmt.Project_Type "Project Type"]</td>
	<td>[im_category_select -include_empty_p 1 "Intranet Project Type" filter_project_type_id $filter_project_type_id]</td>
	</tr>
	<tr>
	<td>[lang::message::lookup "" intranet-release-mgmt.Project_Status "Project Status"]</td>
	<td>[im_category_select -include_empty_p 1 "Intranet Project Status" filter_project_status_id $filter_project_status_id]<br>&nbsp;</td>
	</tr>
	<tr>
	<td>[lang::message::lookup "" intranet-release-mgmt.Ticket_Type "Ticket Type"]</td>
	<td>[im_category_select -include_empty_p 1 "Intranet Ticket Type" filter_ticket_type_id $filter_ticket_type_id]</td>
	</tr>
	<tr>
	<td>[lang::message::lookup "" intranet-release-mgmt.Ticket_Status "Ticket Status"]</td>
	<td>[im_category_select -include_empty_p 1 "Intranet Ticket Status" filter_ticket_status_id $filter_ticket_status_id]<br>&nbsp;</td>
	</tr>
	<tr>
	<td colspan=2><input type=submit name='[lang::message::lookup "" intranet-release-mgmt.Select "Select"]'></td>
	</tr>
	</table>
	</form>
	<br>
      	</div>
	<hr/>
"
