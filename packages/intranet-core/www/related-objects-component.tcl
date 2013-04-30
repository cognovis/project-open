# /packages/intranet-helpdesk/www/related-objects-component.tcl
#
# Copyright (c) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# Shows the list of objects related to the current object

# ---------------------------------------------------------------
# Variables
# ---------------------------------------------------------------

#    { object_id:integer "" }
#    { include_membership_rels_p 0 }
#    return_url 

set show_master_p 0
if {![info exists object_id]} {

    # Allow to run as stand-alone page
    ad_page_contract {
        Shows the list of objects related to the current object
        @author frank.bergmann@project-open.com
    } {
        object_id:integer
        { include_membership_rels_p 0 }
        { return_url "" }
        { limit 100000 }
    }

    set show_master_p 1
}


# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
if { ![info exists include_membership_rels_p] || "" == $include_membership_rels_p} { set include_membership_rels_p 0 }
if { ![info exists hide_object_chk_p] } { set hide_object_chk_p 0 }
if { ![info exists hide_rel_name_p] } { set hide_rel_name_p 0 }
if { ![info exists hide_direction_pretty_p] } { set hide_direction_pretty_p 0 }
if { ![info exists hide_object_type_pretty_p] } { set hide_object_type_pretty_p 0 }
if { ![info exists hide_object_name_p] } { set hide_object_name_p 0 }
if { ![info exists hide_creation_date_formatted_p] } { set hide_creation_date_formatted_p 0 }
if { ![info exists sort_order] || "" == $sort_order } { set sort_order "sort_order, r.rel_type, o.object_type, direction, object_name" }

if {![info exists limit] || "" == $limit} { set limit 20 }

# ---------------------------------------------------------------
# Referenced Objects - Problem objects referenced by THIS object
# ---------------------------------------------------------------

set bulk_actions_list {}
if { !$hide_object_chk_p  } {
    lappend bulk_actions_list "[lang::message::lookup "" intranet-helpdesk.Delete_Association "Delete Association"]" "/intranet/related-objects-delete" "[lang::message::lookup "" intranet-helpdesk.Remove_checked_items "Remove Checked Items"]"
}

# Determine the association link. Each object type has its own custom
# code for associating it with another object type.
#
set object_type [acs_object_type $object_id]
set assoc_msg [lang::message::lookup {} intranet-core.Associated_with_new_Object {Associate with new Object}]
set actions [list]
switch $object_type {
    im_ticket {
	lappend actions $assoc_msg [export_vars -base "/intranet-helpdesk/related-objects-associate" {return_url {tid $object_id}}] ""
    }
    im_sla_parameter {
	lappend actions $assoc_msg [export_vars -base "/intranet-helpdesk/related-objects-associate" {return_url {tid $object_id}}] ""
    }
}

list::create \
    -name rels \
    -multirow rels_multirow \
    -key rel_id \
    -row_pretty_plural "[lang::message::lookup {} intranet-core.Related_Objects "Related Objects"]" \
    -has_checkboxes \
    -bulk_actions $bulk_actions_list \
    -bulk_action_export_vars { object_id return_url } \
    -actions $actions \
    -elements {
	object_chk {
	    label "<input type=\"checkbox\" 
                          name=\"_dummy\" 
                          onclick=\"acs_ListCheckAll('rels_list', this.checked)\" 
                          title=\"Check/uncheck all rows\">"
	    display_template {
		@rels_multirow.object_chk;noquote@
	    }
	    hide_p $hide_object_chk_p
	}
	rel_name {
	    label "[lang::message::lookup {} intranet-helpdesk.Relationship_Type {Relationship}]"
	    hide_p $hide_rel_name_p
	}
	direction_pretty {
	    label "[lang::message::lookup {} intranet-helpdesk.Direction { }]"
	    display_template {
		@rels_multirow.direction_pretty;noquote@
	    }
	    hide_p $hide_direction_pretty_p
	}
	object_type_pretty {
	    label "[lang::message::lookup {} intranet-helpdesk.Object_Type {Type}]"
	    hide_p $hide_object_type_pretty_p
	}
	object_name {
	    label "[lang::message::lookup {} intranet-helpdesk.Object_Name {Name}]"
	    link_url_eval {$object_url}
	    hide_p $hide_object_name_p
	}
	creation_date_formatted {
	    label "[lang::message::lookup {} intranet-core.Created {Created}]"
	    hide_p $hide_creation_date_formatted_p
	}
    }


set membership_rel_exclude_sql ""

if {0 == $include_membership_rels_p} {
    set membership_rel_exclude_sql "rel_type not in ('im_biz_object_member') and"
}

set where_criteria "and 1=1"

if { [info exists show_projects_only] && $show_projects_only } { 
    set where_criteria "and ot.pretty_name = 'Project'" 
    if { !$hide_creation_date_formatted_p  } {
	set sort_order "o.creation_date ASC"	
    }
}

set object_rel_sql "
	select
		o.object_id as oid,
		acs_object__name(o.object_id) as object_name,
		o.object_type as object_type,
		ot.pretty_name as object_type_pretty,
		otu.url as object_url_base,
		r.rel_id,
		r.rel_type as rel_type,
		rt.pretty_name as rel_type_pretty,
		to_char(o.creation_date, 'YYYY-MM-DD') as creation_date_formatted, 
		CASE	WHEN r.object_id_one = :object_id THEN 'incoming'
			WHEN r.object_id_two = :object_id THEN 'outgoing'
			ELSE ''
		END as direction,
                CASE    WHEN o.object_type = 'im_company' THEN 10
                        WHEN o.object_type = 'im_office' THEN 20
                        WHEN o.object_type = 'im_project' THEN 900
                        WHEN o.object_type = 'im_timesheet_task' THEN 910
                        ELSE 500
                END as sort_order
	from
		acs_rels r,
		acs_object_types rt,
		acs_objects o,
		acs_object_types ot
		LEFT OUTER JOIN (select * from im_biz_object_urls where url_type = 'view') otu ON otu.object_type = ot.object_type
	where
		r.rel_type = rt.object_type and
		o.object_type = ot.object_type and
		$membership_rel_exclude_sql
		(
			r.object_id_one = :object_id and
			r.object_id_two = o.object_id
		OR
			r.object_id_one = o.object_id and
			r.object_id_two = :object_id
		) 
		$where_criteria
	order by
		$sort_order
        LIMIT :limit
"

set count 0
db_multirow -extend { object_chk object_url direction_pretty rel_name } rels_multirow object_rels $object_rel_sql {
    set object_url "$object_url_base$oid"
    set object_chk "<input type=\"checkbox\" 
				name=\"rel_id\" 
				value=\"$rel_id\" 
				id=\"rels_list,$rel_id\">
    "
    set rel_name [lang::message::lookup "" intranet-helpdesk.Rel_$rel_type $rel_type_pretty]
    if {"" == $object_name} { set object_name [lang::message::lookup "" intranet-core.Invalid_Object "Invalid Object"] }

    switch $direction {
	incoming { set direction_pretty [im_gif arrow_right] }
	outgoing { set direction_pretty [im_gif arrow_left] }
	default  { set direction_pretty "" }
    }

    incr count
}


set show_more_url ""
if {$count == $limit} {
    set show_more_url "
        <a href='[export_vars -base "/intranet/related-objects-component" {object_id include_membership_rels_p return_url}]'>
        [lang::message::lookup "" intranet-core.Not_all_results_have_been_shown "Not all results have been shown."]<br>
        [lang::message::lookup "" intranet-core.Show_more "Show more..."]
        </a>
    "
}

