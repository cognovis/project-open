# /packages/intranet-helpdesk/www/related-tickets-component.tcl
#
# Copyright (c) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# Shows the list of tickets related to the current ticket

# ---------------------------------------------------------------
# Variables
# ---------------------------------------------------------------

#    { ticket_id:integer "" }
#    return_url 

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]

# ---------------------------------------------------------------
# Referenced Tickets - Problem tickets referenced by THIS ticket
# ---------------------------------------------------------------

set bulk_action_list {}
lappend bulk_actions_list "[lang::message::lookup "" intranet-helpdesk.Delete "Delete"]" "associate-delete" "[lang::message::lookup "" intranet-helpdesk.Remove_checked_items "Remove Checked Items"]"

set actions [list]
set assoc_msg [lang::message::lookup {} intranet-helpdesk.New_Association {Associated with new Object}]
lappend actions $assoc_msg [export_vars -base "/intranet-helpdesk/associate" {return_url {tid $ticket_id}}] ""

list::create \
    -name tickets \
    -multirow tickets_multirow \
    -key rel_id \
    -row_pretty_plural "[lang::message::lookup {} intranet-helpdesk.Associated_Objects "Associated Objects"]" \
    -has_checkboxes \
    -bulk_actions $bulk_actions_list \
    -bulk_action_export_vars { ticket_id return_url } \
    -actions $actions \
    -elements {
	ticket_chk {
	    label "<input type=\"checkbox\" 
                          name=\"_dummy\" 
                          onclick=\"acs_ListCheckAll('tickets_list', this.checked)\" 
                          title=\"Check/uncheck all rows\">"
	    display_template {
		@tickets_multirow.ticket_chk;noquote@
	    }
	}
	rel_name {
	    label "[lang::message::lookup {} intranet-helpdesk.Relationship_Type {Relationship}]"
	}
	direction_pretty {
	    label "[lang::message::lookup {} intranet-helpdesk.Direction { }]"
	}
	object_type_pretty {
	    label "[lang::message::lookup {} intranet-helpdesk.Object_Type {Type}]"
	}
	object_name {
	    label "[lang::message::lookup {} intranet-helpdesk.Object_Name {Object Name}]"
	    link_url_eval {$object_url}
	}
    }


set object_rel_sql "
	select
		o.object_id,
		acs_object__name(o.object_id) as object_name,
		o.object_type as object_type,
		ot.pretty_name as object_type_pretty,
		otu.url as object_url_base,

		r.rel_id,
		r.rel_type as rel_type,
		rt.pretty_name as rel_type_pretty,

		CASE	WHEN r.object_id_one = :ticket_id THEN 'incoming'
			WHEN r.object_id_two = :ticket_id THEN 'outgoing'
			ELSE ''
		END as direction
	from
		acs_rels r,
		acs_object_types rt,
		acs_objects o,
		acs_object_types ot
		LEFT OUTER JOIN (select * from im_biz_object_urls where url_type = 'view') otu ON otu.object_type = ot.object_type
	where
		r.rel_type = rt.object_type and
		o.object_type = ot.object_type and
		rel_type not in ('im_biz_object_member') and   -- handled by the Ticket Members component
		(
			r.object_id_one = :ticket_id and
			r.object_id_two = o.object_id
		OR
			r.object_id_one = o.object_id and
			r.object_id_two = :ticket_id
		)
	order by
		direction
"

db_multirow -extend { ticket_chk object_url direction_pretty rel_name } tickets_multirow object_rels $object_rel_sql {
    set object_url "$object_url_base$object_id"
    set ticket_chk "<input type=\"checkbox\" 
				name=\"rel_id\" 
				value=\"$rel_id\" 
				id=\"tickets_list,$rel_id\">
    "
    set rel_name [lang::message::lookup "" intranet-helpdesk.Rel_$rel_type $rel_type_pretty]

    switch $direction {
	incoming { set direction_pretty " -> " }
	outgoing { set direction_pretty " <- " }
	default  { set direction_pretty "" }
    }
}

