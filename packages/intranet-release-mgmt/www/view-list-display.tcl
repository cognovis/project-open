# -------------------------------------------------------------
# intranet-release-mgmt/www/view-list-display.tcl
#
# (c) 2003-2007 ]project-open[
# All rights reserved
# Author: frank.bergmann@project-open.com
#
# Display component - this component is being used both by a 
# ]po[ "component" and by the normal release list page.

# -------------------------------------------------------------
# Variables:
# project_id:integer
# return_url

set page_title [lang::message::lookup "" intranet-release-mgmt.Release_Items "Release Items"]
set package_url "/intranet-release-mgmt"
set release_project_id $project_id
set return_url [im_url_with_query]
set add_item_url [export_vars -base "/intranet-release-mgmt/add-items" {release_project_id return_url}]

# -------------------------------------------------------------
# Permissions
#
# The project admin (=> Release Manager) can do everything.
# The managers of the individual Release Items can change 
# _their_ release stati.

set user_id [ad_maybe_redirect_for_registration]
im_project_permissions $user_id $project_id view read write admin
set edit_all_items_p $write

# -------------------------------------------------------------
# Create the list

set bulk_actions_list [list]
lappend bulk_actions_list "Save Status Changes" "$package_url/save-items" "Save status of release items"
if {$edit_all_items_p} { lappend bulk_actions_list "Delete Checked Release Items" "$package_url/del-items" "Removed checked release items" }

set elements {
	item_name {
	    display_col item_name
	    label "Release Item"
	    link_url_eval $release_item_url
	}
	project_lead_id {
	    display_col project_lead_name
	    label "Project Manager"
	    link_url_eval $project_lead_url
	}
    }


set custom_cols [parameter::get_from_package_key -package_key "intranet-release-mgmt" -parameter "ReleaseMgmtReleaseItemsCustomColumns" -default ""]

foreach col $custom_cols {
    set col_title [lang::message::lookup "" intranet-release-mgmt.[lang::util::suggest_key $col] $col]
    lappend elements $col
    lappend elements [list label $col_title ]
}

lappend elements release_status 
lappend elements {
	    label "Release Status"
	    display_template {
		@release_items.release_status_template;noquote@
	    }
	}

lappend elements sort_order 
lappend elements {
	    label "Ord"
	    display_template { @release_items.sort_order_template;noquote@ }
	}

lappend elements item_chk 
lappend elements {
	    label "<input type=\"checkbox\"
			  name=\"_dummy\"
			  onclick=\"acs_ListCheckAll('item_list', this.checked)\"
			  title=\"Check/uncheck all rows\">"
	    display_template {
		@release_items.item_chk;noquote@
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
    -bulk_action_export_vars  {
	release_project_id
	return_url
    } \
    -bulk_action_method GET \
    -elements $elements


set extra_selects [list "0 as zero"]
set column_sql "
        select  w.deref_plpgsql_function,
                aa.attribute_name
        from    im_dynfield_widgets w,
                im_dynfield_attributes a,
                acs_attributes aa
        where   a.widget_name = w.widget_name and
                a.acs_attribute_id = aa.attribute_id and
                aa.object_type = 'im_project'
"
db_foreach column_list_sql $column_sql {
    lappend extra_selects "${deref_plpgsql_function}($attribute_name) as ${attribute_name}_deref"
}
set extra_select [join $extra_selects ",\n\t"]

db_multirow -extend { 
	release_item_url 
	release_status_template 
	item_chk 
	project_lead_url
	sort_order_template
} release_items select_release_items "
	select
		perm.admin_p,
		i.release_status_id,
		im_category_from_id(i.release_status_id) as release_status,
		p.project_name as item_name,
		p.project_id as item_id,
		im_name_from_user_id(p.project_lead_id) as project_lead_name,
		p.*,
		i.sort_order,
		$extra_select
 	from
		im_projects p
		LEFT OUTER JOIN (
			select	count(*) as admin_p,
				r.object_id_one as project_id
			from	acs_rels r,
				im_biz_object_members m
			where	object_id_two = 624
				and m.rel_id = r.rel_id
				and m.object_role_id = 1301
			group by
				project_id
		) perm ON (p.project_id = perm.project_id),
		acs_rels r,
		im_release_items i
	where
		r.rel_id = i.rel_id
		and r.object_id_two = p.project_id
		and r.object_id_one = :release_project_id
	order by
		i.sort_order
" {
    set release_item_url [export_vars -base "/intranet/projects/view?" {project_id return_url}]

    set project_lead_url [export_vars -base "/intranet/users/view?" {{user_id $project_lead_id} return_url}]

    set release_status_template $release_status
    if {$edit_all_items_p || ("" != $admin_p && $admin_p)} {
	set release_status_template [im_category_select "Intranet Release Status" "release_status_id.$item_id" $release_status_id]
    }

    set item_chk "<input type=\"checkbox\"
	name=\"item_id\"
	value=\"$item_id\"
	id=\"item_list,$item_id\">
    "

#    set sort_order_template "
#	<nobr>
#	<a href=\"[export_vars -base "/intranet-release-mgmt/order-item" {{dir up} release_project_id project_id return_url} ]\">[im_gif arrow_comp_up]</a>
#	<a href=\"[export_vars -base "/intranet-release-mgmt/order-item" {{dir down} release_project_id project_id return_url} ]\">[im_gif arrow_comp_down]</a>
#	</nobr>
#    "

    set sort_order_template "
	<input type=text name=\"release_sort_order.$item_id\" size=5 value=\"$sort_order\">
    "
}
