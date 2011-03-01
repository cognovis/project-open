ad_page_contract {

    @author Matthew Geddert openacs@geddert.com
    @author Frank Bergmann frank.bergmann@project-open.com
    @creation-date 2005-01-07
} {
    object_type
    table_name
    id_column
    return_url
}

# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}


# ------------------------------------------------------------------
# 
# ------------------------------------------------------------------

acs_object_type::get -object_type $object_type -array "object_info"

set title "Define Options"
set context [list [list objects Objects] [list "object-type?object_type=$object_type" $object_info(pretty_name)] [list "attribute-add?object_type=$object_type" "Add Attribute"] $title]


db_dml insert_table "
    insert into acs_object_type_tables (
	object_type,
	table_name,
	id_column
    ) values (
	:object_type,
	:table_name,
	:id_column
    )
"

ad_returnredirect $return_url
