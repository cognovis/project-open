# -------------------------------------------------------------
# /packages/intranet-planning/www/planning-component.tcl
#
# Copyright (c) 2010 ]project-open[
# All rights reserved.
#
# Author: frank.bergmann@project-open.com
#

# -------------------------------------------------------------
# Variables from intranet-planning-procs:
#	object_id:integer
#	planning_type_id
#	planning_time_dim_id 73202
#	planning_dim1 ""
#	planning_dim2 ""
#	planning_dim3 ""
#	restrict_to_main_project_p 1

if {![info exists object_id]} {
    ad_page_contract {
	@author frank.bergmann@project-open.com
    } {
	object_id:integer
	{planning_type_id 73100}
	{planning_time_dim_id 73202 }
	{planning_dim1 "" }
	{planning_dim2 "" }
	{planning_dim3 "" }
    }
}

if {![info exists return_url] || "" == $return_url} { set return_url [im_url_with_query] }
set user_id [ad_maybe_redirect_for_registration]
set new_item_url [export_vars -base "/intranet-planning/new" {object_id return_url}]

# Check the permissions
# Permissions for all usual projects, companies etc.
set object_type [db_string acs_object_type "select object_type from acs_objects where object_id = :object_id"]
set perm_cmd "${object_type}_permissions \$user_id \$object_id object_view object_read object_write object_admin"
eval $perm_cmd
# object_read is evaluated by .adp which will return nothing if not set.

# Get the start date of the project or now() as a default.
db_1row start_date "
	select	to_char(now()::date, 'YYYY') as year,
		to_char(now()::date, 'MM') as month
"
db_0or1row start_date "
	select	to_char(start_date, 'YYYY') as year,
		to_char(start_date, 'MM') as month
	from	im_projects
	where	project_id = :object_id
"

# Get the list of months
set months [list]
for {set m 0} {$m < 12} {incr m} {
    lappend months "$year<br>$month"
    # Remove leading "0"
    set month [string trimleft $month "0"]
    incr month
    if {$month > 12} {
	incr year
	set month "1"
    }
    if {[string length $month] < 2} { set month "0$month" }
}

# ----------------------------------------------------
# Create a "multirow" to show the results

multirow create items item_type item item_formatted
if {$object_read} {

    set items_sql "
	select
		children.*,
		pi.*,
		bou.url as object_base_url,
		im_category_from_id(children.project_status_id) as project_status,
		im_category_from_id(children.project_type_id) as project_type,
		tree_level(children.tree_sortkey) - tree_level(parent.tree_sortkey) as level
	from
		im_projects parent,
		im_projects children
		LEFT OUTER JOIN (
			select	pi.*
			from	im_planning_items pi
			where	pi.item_type_id = :planning_type_id and
				pi.item_time_dim_id = :planning_time_dim_id
		) pi ON (children.project_id = pi.item_object_id)
		LEFT OUTER JOIN acs_objects o ON (pi.item_object_id = o.object_id)
		LEFT OUTER JOIN (
			select	*
			from	im_biz_object_urls
			where	url_type = 'view'
		) bou ON (o.object_type = bou.object_type)
	where
		children.project_type_id not in ([im_project_type_task], [im_project_type_ticket]) and
		children.project_status_id not in ([join [im_sub_categories [im_project_status_closed]] ","]) and
		children.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey) and
		parent.project_id = :object_id
	order by children.tree_sortkey
    "
    
    db_multirow -extend { item_formatted item_object_url } items items_query $items_sql {
	set item_object_url "$object_base_url$item_object_id"

    }

}