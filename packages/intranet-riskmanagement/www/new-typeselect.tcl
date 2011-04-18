# /packages/intranet-riskmanagement/www/new-typeselect.tcl
#
# Copyright (c) 2008 ]project-open[
#

ad_page_contract {
    We get redirected here from the risk's "New" page if there
    are DynFields per object subtype and no type is specified.

    @author frank.bergmann@project-open.com
} {
    return_url
    risk_id:optional
    { risk_name "" }
    { risk_nr "" }
    { risk_sla_id "" }
    { risk_type_id "" }
    { risk_customer_id "" }
}

# No permissions necessary, that's handled by the object's new page
# Here we just select an object_type_id for the given object.

set current_user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-riskmanagement.Please_Select_a_Risk_Type "Please Select a Risk Type"]
set context_bar [im_context_bar $page_title]

set sql "
	select	c.category_id,
		c.category,
		c.category_description,
		p.parent_id
	from	im_categories c
		LEFT OUTER JOIN (select * from im_category_hierarchy) p ON p.child_id = c.category_id
	where	c.category_type = 'Intranet Risk Type' and
		(c.enabled_p is null or c.enabled_p = 't') 
	order by parent_id, category
"

set ttt {
		and exists (
			select	*
			from	im_category_hierarchy
			where	child_id = c.category_id
		)
}

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
		<nobr><input type=radio name=risk_type_id value=$category_id>$category_l10n</input>&nbsp;</nobr>
		</td>
		<td>$comment</td>
	</tr>
    "

}
