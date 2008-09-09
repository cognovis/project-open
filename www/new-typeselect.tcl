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

set user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-helpdesk.Please_Select_Ticket_Properties "Please select ticket properties"]
set context_bar [im_context_bar $page_title]

set ticket_sla_options [im_select_flatten_list [im_helpdesk_ticket_sla_options -customer_id $ticket_customer_id -include_create_sla_p 1]]

# ad_return_complaint 1 "sla=$ticket_sla_id, type=$ticket_type_id"

set sql "
	select	c.*
	from	im_categories c
	where	c.category_type = 'Intranet Ticket Type'
		and (c.enabled_p is null or c.enabled_p = 't')
	order by
		category
"
db_foreach cats $sql {

    regsub -all " " $category "_" category_key
    set category_l10n [lang::message::lookup "" intranet-core.category_key $category]
    set category_comment_key ${category_key}_comment

    set comment $category_description
    if {"" == $comment} { set comment " " }
    set comment [lang::message::lookup "" intranet-core.$category_comment_key $comment]

    append category_select_html "
	<tr>
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
