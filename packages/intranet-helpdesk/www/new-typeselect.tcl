# /packages/intranet-helpdesk/www/new-typeselect.tcl
#
# Copyright (c) 2008 ]project-open[
#

ad_page_contract {
    We get redirected here from the ticket's "New" page if there
    are DynFields per object subtype and no type is specified.

    @author frank.bergmann@project-open.com
} {
    return_url
    ticket_id:optional
    { ticket_name "" }
    { ticket_nr "" }
    { ticket_sla_id "" }
    { ticket_type_id "" }
    { ticket_customer_id "" }
}

# No permissions necessary, that's handled by the object's new page
# Here we just select an object_type_id for the given object.

set current_user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-helpdesk.Please_Select_Ticket_Properties "Please select ticket properties"]
set context_bar [im_context_bar $page_title]

set ticket_sla_options [im_select_flatten_list [im_helpdesk_ticket_sla_options -customer_id $ticket_customer_id -include_create_sla_p 1 -include_empty_p 0]]

if {0 == [llength $ticket_sla_options]} {
    set user_name [db_string uname "select acs_object__name(:current_user_id)"]
    ad_return_complaint 1 "
	<br><b>[lang::message::lookup "" intranet-helpdesk.No_SLAs_for_customer "No SLA available"]</b>:<br>&nbsp;<br>
	[lang::message::lookup "" intranet-helpdesk.No_SLAs_for_customer_msg "
		There is no SLA (Service Level Agreement / Support Contract) <br>
		available in this system for user '%user_name%'<br>
		Please contact the support team to create or reactivate a SLA.
		<br>&nbsp;<br>
	"]
    "
    ad_script_abort
}

# ad_return_complaint 1 "sla=$ticket_sla_id, type=$ticket_type_id"

set sql "
	select
		c.category_id,
		c.category,
		c.category_description,
		p.parent_id
	from
		im_categories c
		LEFT OUTER JOIN (select * from im_category_hierarchy) p ON p.child_id = c.category_id
	where
		c.category_type = 'Intranet Ticket Type' and
		(c.enabled_p is null or c.enabled_p = 't') and
		exists (
			select	*
			from	im_category_hierarchy
			where	child_id = c.category_id
		)
	order by
		parent_id,
		category
"

set category_select_html ""
set old_parent_id ""
db_foreach cats $sql {

    if {$old_parent_id != $parent_id} {
	append category_select_html "<tr><td colspan=2><b>[im_category_from_id $parent_id]</b><br></td></tr>\n"
	set old_parent_id $parent_id
    }

    regsub -all " " $category "_" category_key
    set category_l10n [lang::message::lookup "" intranet-core.$category_key $category]
    set category_comment_key ${category_key}_comment

    set comment $category_description
    if {"" == $comment} { set comment " " }
    set comment [lang::message::lookup "" intranet-core.$category_comment_key $comment]

    append category_select_html "
	<tr>
		<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
		<td>
		<nobr>
		<input type=radio name=ticket_type_id value=$category_id>$category_l10n</input>
		&nbsp;
		</nobr>
		</td>
		<td>$comment</td>
	</tr>
    "

}
