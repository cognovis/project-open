# /packages/intranet-confdb/tcl/intranet-confdb-procs.tcl
#
# Copyright (C) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# Constants
# ----------------------------------------------------------------------

ad_proc -public im_conf_item_status_active {} { return 11700 }
ad_proc -public im_conf_item_status_deleted {} { return 11702 }

ad_proc -public im_conf_item_type_hardware {} { return 11800 }
ad_proc -public im_conf_item_type_software {} { return 11802 }
ad_proc -public im_conf_item_type_process {} { return 11804 }
ad_proc -public im_conf_item_type_license {} { return 11806 }
ad_proc -public im_conf_item_type_specs {} { return 11808 }
ad_proc -public im_conf_item_type_service {} { return 11810 }


ad_proc -public im_conf_item_type_po_package {} { return 12008 }


# ----------------------------------------------------------------------
# PackageID
# ----------------------------------------------------------------------

ad_proc -public im_package_conf_items_id {} {
    Returns the package id of the intranet-confdb module
} {
    return [util_memoize "im_package_conf_items_id_helper"]
}

ad_proc -private im_package_conf_items_id_helper {} {
    return [db_string im_package_core_id {
        select package_id from apm_packages
        where package_key = 'intranet-confdb'
    } -default 0]
}


namespace eval im_conf_item {

    ad_proc -public new {
        { -var_hash "" }
    } {
        Create a new configuration item.
	There are only few required field.
	Primary key is conf_item_nr which defaults to conf_item_name.

        @author frank.bergmann@project-open.com
	@return The object_id of the new (or existing) Conf Item.
    } {
	catch { set current_user_id [ad_get_user_id] }
	catch { set peeraddr [ad_conn peeraddr] }
	if {![info exists current_user_id]} { set current_user_id [util_memoize [list db_string first_user {select min(person_id) from persons where person_id > 0}]] }
	if {![info exists peeraddr]} { set peeraddr "0.0.0.0" }

	array set vars $var_hash
	set conf_item_new_sql "
		select im_conf_item__new(
			null,
			'im_conf_item',
			now(),
			:current_user_id,
			:peeraddr,
			null,
			:conf_item_name,
			:conf_item_nr,
			:conf_item_parent_id,
			:conf_item_type_id,
			:conf_item_status_id
		)
	"

	# Set defaults.
	set conf_item_name $vars(conf_item_name)
	set conf_item_nr $conf_item_name
	set conf_item_code $conf_item_name
	set conf_item_parent_id ""
	set conf_item_status_id [im_conf_item_status_active]
	set conf_item_type_id [im_conf_item_type_hardware]
	set conf_item_version ""
	set conf_item_owner_id [ad_get_user_id]
	set description ""
	set note ""

	# Override defaults
	if {[info exists vars(conf_item_nr)]} { set conf_item_nr $vars(conf_item_nr) }
	if {[info exists vars(conf_item_code)]} { set conf_item_code $vars(conf_item_nr) }
	if {[info exists vars(conf_item_parent_id)]} { set conf_item_parent_id $vars(conf_item_parent_id) }
	if {[info exists vars(conf_item_status_id)]} { set conf_item_status_id $vars(conf_item_status_id) }
	if {[info exists vars(conf_item_type_id)]} { set conf_item_type_id $vars(conf_item_type_id) }
	if {[info exists vars(conf_item_version)]} { set conf_item_version $vars(conf_item_version) }
	if {[info exists vars(conf_item_owner_id)]} { set conf_item_owner_id $vars(conf_item_owner_id) }
	if {[info exists vars(description)]} { set description $vars(description) }
	if {[info exists vars(note)]} { set note $vars(note) }

	# Check if the item already exists
        set conf_item_id [db_string exists "
		select	conf_item_id
		from	im_conf_items
		where
			conf_item_parent_id = :conf_item_parent_id and
			conf_item_nr = :conf_item_nr
	" -default 0]

	# Create a new item if necessary
        if {!$conf_item_id} { set conf_item_id [db_string new $conf_item_new_sql] }

	# Update the item with additional variables from the vars array
	set sql_list [list]
	foreach var [array names vars] {
	    if {$var == "conf_item_id"} { continue }
	    lappend sql_list "$var = :$var"
	}
	set sql "
		update im_conf_items set
		[join $sql_list ",\n"]
		where conf_item_id = :conf_item_id
	"
        db_dml update_conf_item $sql
	return $conf_item_id
    }


}




# ----------------------------------------------------------------------
# Generate generic select SQL for Conf Items
# to be used in list pages, options, ...
# ---------------------------------------------------------------------


ad_proc -public im_conf_item_select_sql { 
    {-type_id ""} 
    {-status_id ""} 
    {-project_id ""} 
    {-owner_id ""} 
    {-cost_center_id ""} 
    {-var_list "" }
    {-parent_id ""}
    {-treelevel 0}
} {
    Returns an SQL statement that allows you to select a range of
    configuration items, given a number of conditions.
    This SQL is used for example in the ConfItemListPage, in
    im_conf_item_options and others.
    The variable names returned by the SQL adhere to the ]po[ coding
    standards. Important returned variables include:
	- im_conf_items.*, (all fields from the base table)
	- conf_item_status, conf_item_type, (status and type human readable)
} {
    set current_user_id [ad_get_user_id]
    # Deal with generically passed variables as replacement of parameters.
    array set var_hash $var_list
    foreach var_name [array names var_hash] { set $var_name $var_hash($var_name) }

    set extra_froms [list]
    set extra_wheres [list]

    if {"" != $owner_id} {
	lappend extra_wheres "owner_rel.object_id_one = i.conf_item_id"
	lappend extra_wheres "(owner_rel.object_id_two = :owner_id OR conf_item_owner_id = :owner_id)"
	lappend extra_froms "acs_rels owner_rel"
    }
    if {"" != $project_id} {
	lappend extra_wheres "project_rel.object_id_two = i.conf_item_id"
	lappend extra_wheres "project_rel.object_id_one = :project_id"
	lappend extra_froms "acs_rels project_rel"
    }

    # -----------------------------------------------
    # Permissions

    set perm_where "
	('t' = acs_permission__permission_p([subsite::main_site_id], [ad_get_user_id], 'view_conf_items_all') OR
	i.conf_item_id in (
		-- User is explicit member of conf item
		select	ci.conf_item_id
		from	im_conf_items ci,
			acs_rels r
		where	r.object_id_two = [ad_get_user_id] and
			r.object_id_one = ci.conf_item_id
	UNION
		-- User belongs to project that belongs to conf item
		select	ci.conf_item_id
		from	im_conf_items ci,
			im_projects p,
			acs_rels r1,
			acs_rels r2
		where	r1.object_id_two = [ad_get_user_id] and
			r1.object_id_one = p.project_id and
			r2.object_id_two = ci.conf_item_id and
			r2.object_id_one = p.project_id
	UNION
		-- User belongs to a company which is the customer of project that belongs to conf item
		select	ci.conf_item_id
		from	im_companies c,
			im_conf_items ci,
			im_projects p,
			acs_rels r1,
			acs_rels r2
		where	r1.object_id_two = [ad_get_user_id] and
			r1.object_id_one = c.company_id and
			p.company_id = c.company_id and
			r2.object_id_two = ci.conf_item_id and
			r2.object_id_one = p.project_id
	))
    "

    # -----------------------------------------------
    # Join the query parts

    if {"" != $cost_center_id} { lappend extra_wheres "i.conf_item_cost_center_id = :cost_center_id" }
    if {"" != $status_id} { lappend extra_wheres "i.conf_item_status_id in ([join [im_sub_categories $status_id] ","])" }
    if {"" != $type_id} { lappend extra_wheres "i.conf_item_type_id in ([join [im_sub_categories $type_id] ","])" }
    if {"" != $treelevel} { lappend extra_wheres "tree_level(i.tree_sortkey) <= 1+$treelevel" }
    if {"" != $perm_where} { lappend extra_wheres $perm_where }
    if {"" != $parent_id} { 
	lappend extra_wheres "parent.conf_item_id = $parent_id" 
	lappend extra_wheres "i.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey)" 
	lappend extra_wheres "i.conf_item_id != parent.conf_item_id" 
	lappend extra_froms "im_conf_items parent"
    }

    set extra_from [join $extra_froms "\n\t\t,"]
    set extra_where [join $extra_wheres "\n\t\tand "]

    if {"" != $extra_from} { set extra_from ",$extra_from" }
    if {"" != $extra_where} { set extra_where "and $extra_where" }

    set select_sql "
        select distinct
		i.*,
		tree_level(i.tree_sortkey)-1 as conf_item_level,
		im_category_from_id(i.conf_item_status_id) as conf_item_status,
		im_category_from_id(i.conf_item_type_id) as conf_item_type,
		im_conf_item_name_from_id(i.conf_item_parent_id) as conf_item_parent,
		im_cost_center_code_from_id(i.conf_item_cost_center_id) as conf_item_cost_center,
		im_name_from_user_id(i.conf_item_owner_id) as conf_item_owner
        from	im_conf_items i	
		$extra_from
	where	1=1 
		$extra_where
	order by
		i.tree_sortkey
    "

    return $select_sql
}

ad_proc -public im_conf_item_update_sql { 
    {-include_dynfields_p 0}
} {
    Returns an SQL statement that updates all Conf Item fields from
    variables according to the ]po[ coding conventions.
} {
    set update_sql "
	update im_conf_items set
		conf_item_name =	:conf_item_name,
		conf_item_nr =		:conf_item_nr,
		conf_item_code =	:conf_item_code,
		conf_item_version =	:conf_item_version,
		conf_item_parent_id =	:conf_item_parent_id,
		conf_item_type_id =	:conf_item_type_id,
		conf_item_status_id =	:conf_item_status_id,
		conf_item_owner_id =	:conf_item_owner_id,
		description = 		:description,
		note = 			:note
	where conf_item_id = :conf_item_id
    "
}


# ----------------------------------------------------------------------
# Delete a conf item
# ---------------------------------------------------------------------
ad_proc -public im_conf_item_delete {
    -conf_item_id:required
} {
    Delete a configuration iem
} {
    set parent_p [db_string parent "select count(*) from im_conf_items where conf_item_parent_id = :conf_item_id"]
    if {$parent_p > 0} { ad_return_complaint 1 "<b>Can't Delete Conf Item</b>:<br>The configuration item is the parent of another conf item. <br>Please delete the children first." }

    db_transaction {
	
	# Delete any user that might be associated with Conf Item
	set user_rels_sql "
		select	r.*
		from	acs_rels r,
			persons p
		where	object_id_two = p.person_id
			and object_id_one = :conf_item_id
	"
	db_foreach user_rels_del $user_rels_sql {
	    db_string del_user_rel "select im_biz_object_member__delete(:object_id_one, :object_id_two)"
	}

	# Delete any user that might be associated with Conf Item
	set conf_proj_rels_sql "
		select	r.*
		from	acs_rels r,
			im_projects p
		where	object_id_one = p.project_id
			and object_id_two = :conf_item_id
	"
	db_foreach conf_proj_rels_del $conf_proj_rels_sql {
	    db_string del_conf_proj_rel "select im_conf_item_project_rel__delete(:rel_id)"
	}

	db_string del_conf_item "select im_conf_item__delete(:conf_item_id)"
    }
}

# ----------------------------------------------------------------------
# Permissions
# ---------------------------------------------------------------------


ad_proc -public im_conf_item_permissions {user_id conf_item_id view_var read_var write_var admin_var} {
    Fill the "by-reference" variables read, write and admin
    with the permissions of $user_id on $conf_item_id
} {
    upvar $view_var view
    upvar $read_var read
    upvar $write_var write
    upvar $admin_var admin

    set read [im_permission $user_id view_conf_items_all]
    set write [im_permission $user_id edit_conf_items_all]
    set admin [im_permission $user_id edit_conf_items_all]

    set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
    set user_is_wheel_p [im_profile::member_p -profile_id [im_wheel_group_id] -user_id $user_id]
    set user_is_group_member_p [im_biz_object_member_p $user_id $conf_item_id]
    set user_is_group_admin_p [im_biz_object_admin_p $user_id $conf_item_id]

    # Admin permissions to global + intranet admins + group administrators
    set user_admin_p [expr $user_is_admin_p || $user_is_group_admin_p || $user_is_wheel_p]

    if {$user_admin_p} {
	set read 1
	set write 1
	set admin 1
    }

    # Tricky: Check if the user is the owner of one of the parent CIs...
    # ToDo: not yet implemented...

    # No explict view perms - set to tread
    set view $read

    # No read - no write...
    if {!$read} {
	set write 0
	set admin 0
    }
}


# ----------------------------------------------------------------------
# Options for ad_form
# ---------------------------------------------------------------------

ad_proc -public im_conf_item_options { 
    {-include_empty_p 0} 
    {-include_empty_name ""} 
    {-type_id ""} 
    {-status_id ""} 
    {-project_id ""} 
    {-owner_id ""} 
    {-cost_center_id ""} 
} {
    Returns a list of all Conf Items.
} {
    set var_list [list type_id $type_id status_id $status_id project_id $project_id owner_id $owner_id cost_center_id $cost_center_id]
    set options_sql [im_conf_item_select_sql -var_list $var_list]

    set options [list]
    if {$include_empty_p} { lappend options [list $include_empty_name ""] }

    set cnt 0
    db_foreach conf_item_options $options_sql {
        set spaces ""
        for {set i 0} {$i < $conf_item_level} { incr i } {
            append spaces "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
        }
        lappend options [list "$spaces$conf_item_name" $conf_item_id]
	incr cnt
    }

    if {!$cnt && $include_empty_p} {
	set not_found [lang::message::lookup "" intranet-confdb.No_Conf_Items_Found "No Conf Items found"]
	lappend options [list $not_found ""]
    }

    return $options
}

# ----------------------------------------------------------------------
# Components
# ---------------------------------------------------------------------

ad_proc -public im_conf_item_list_component {
    { -object_id 0 }
} {
    Returns a HTML component to show all project related conf items
} {
    set params [list \
	[list base_url "/intranet-confdb/"] \
	[list object_id $object_id] \
	[list return_url [im_url_with_query]] \
    ]

    set result [ad_parse_template -params $params "/packages/intranet-confdb/www/conf-item-list-component"]
    set result [string trim $result]
    return [string trim $result]
}


# ----------------------------------------------------------------------
# Conf Item - Project Relationship
# ---------------------------------------------------------------------

ad_proc -public im_conf_item_new_project_rel {
    -project_id:required
    -conf_item_id:required
    {-sort_order 0}
} {
    Establishes as is-conf-item-of relation between conf item and project
} {
    if {"" == $project_id} { ad_return_complaint 1 "Internal Error - project_id is NULL" }
    if {"" == $conf_item_id} { ad_return_complaint 1 "Internal Error - conf_item_id is NULL" }

    set rel_id [db_string rel_exists "
	select	rel_id
	from	acs_rels
	where	object_id_one = :project_id
		and object_id_two = :conf_item_id
    " -default 0]
    if {0 != $rel_id} { return $rel_id }

    return [db_string new-conf-project_rel "
	select im_conf_item_project_rel__new (
		null,
		'im_conf_item_project_rel',
		:project_id,
		:conf_item_id,
		null,
		[ad_get_user_id],
		'[ad_conn peeraddr]',
		:sort_order
	)
    "]
}



# ----------------------------------------------------------------------
# Navigation Bar Tree
# ---------------------------------------------------------------------

ad_proc -public im_navbar_tree_confdb { } {
    Creates an <ul> ...</ul> collapsable menu for the
    system's main NavBar.
} {
    set html "
	<li><a href=/intranet-confdb/index>[lang::message::lookup "" intranet-confdb.Conf_Mgmt "Configuration Management"]</a>
	<ul>
    "

    # Create new Conf Item
    append html "<li><a href=\"/intranet-confdb/new\">[lang::message::lookup "" intranet-confdb.New_Conf_Item "Create a new Conf Item"]</a>\n"

    # Add sub-menu with types of conf_items
    append html "
	<li><a href=\"/intranet-confdb/index\">[lang::message::lookup "" intranet-confdb.Conf_Item_Types "Conf Items Types"]</a>
	<ul>
    "

    set conf_item_type_sql "
	select	t.*
	from	im_conf_item_type t 
	where not exists (select * from im_category_hierarchy h where h.child_id = t.conf_item_type_id)
    "
    db_foreach conf_item_types $conf_item_type_sql {
	set url [export_vars -base "/intranet-confdb/index" {{type_id $conf_item_type_id}}]
        regsub -all " " $conf_item_type "_" conf_item_type_subst
	set name [lang::message::lookup "" intranet-helpdesk.Conf_Item_type_$conf_item_type_subst "$conf_item_type"]
	append html "<li><a href=\"$url\">$name</a></li>\n"
    }
    append html "
	</ul>
	</li>
    "


    append html "
	</ul>
	</li>
    "
    return $html
}


