ad_page_contract {

    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date 2004-07-28
    @cvs-id $Id: index.tcl,v 1.8 2009/06/30 14:02:38 po34demo Exp $

} {
}

set page_title "DynField Extensible Architecture"
set context_bar [im_context_bar $page_title]

set package_id [apm_package_id_from_key "intranet-dynfield"]
set param_url [export_vars -base "/shared/parameters" -url {package_id {return_url "/intranet-dynfield"}}]

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

# -----------------------------------------------------
# Check for DynFields without entry in im_dynfield_layout

set missing_dynfield_object_types ""
set missing_sql "
	select	da.attribute_id as dynfield_attribute_id,
		aa.attribute_id as acs_attribute_id,
		aa.attribute_name,
		aa.object_type
	from
		im_dynfield_attributes da,
		acs_attributes aa
	where
		da.acs_attribute_id = aa.attribute_id and
		da.attribute_id not in (
			select	attribute_id
			from	im_dynfield_layout
			where	page_url = 'default'
		)
	order by
		aa.object_type,
		aa.attribute_name
"
db_foreach missing_map_entries $missing_sql {
    append missing_dynfield_object_types "<li>$object_type: <a href=\"/intranet-dynfield/attribute-new?attribute_id=$dynfield_attribute_id\">$attribute_name</a>\n"
}



ad_return_template
