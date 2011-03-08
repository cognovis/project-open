# /packages/intranet-reporting-indicators/www/index-object-select.tcl
#
# Copyright (c) 2008-2010 ]project-open[
#

ad_page_contract {
    We get redirected here from the indicator's index screen if the user
    has selected an object type != ""
    This page allows the user to select an object of this object as a
    sample for the indicators.

    @author frank.bergmann@project-open.com
} {
    return_url
    object_type
}

set current_user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-reporting-indicators.Please_select_a_sample_object "Please select a sample object for indicators"]
set context_bar [im_context_bar $page_title]

set submit_msg [lang::message::lookup "" intranet-reporting-indicators.Submit "Submit"]

set sql "
	select	*
	from	(select	acs_object__name(object_id) as object_name,
			object_id
		from	acs_objects o
		where	o.object_type = :object_type) o
	where
		object_name is not null and
		object_name != ''
	order by object_name
"

db_foreach objects $sql {

    append object_select_html "
	<tr>
		<td>
		<nobr>
		<input type=radio name=object_id value=$object_id>$object_name</input>
		</nobr>
		</td>
	</tr>
    "

}
