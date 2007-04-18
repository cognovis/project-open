ad_page_contract {

    @author Matthew Geddert openacs@geddert.com
    @author Frank Bergmann frank.bergmann@project-open.com
    @creation-date 2005-01-05
    @cvs-id $Id$

} {
    {object_type:notnull}
    orderby:optional
    {show_interfaces_p "0"}
}

# ******************************************************
# Default & Security
# ******************************************************

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set return_url "[ad_conn url]?[ad_conn query]"
set return_url_encoded [ns_urlencode $return_url]

acs_object_type::get -object_type $object_type -array "object_info"

set object_type_pretty_name $object_info(pretty_name)

set title "Dynfield Attributes of $object_type_pretty_name"
set context [list [list "/intranet-dynfield/" "DynField"] [list "object-types" "Object Types"] $title]


db_1row object_type_info "
select
        pretty_name as object_type_pretty_name,
        table_name,
        id_column
from
        acs_object_types
where
        object_type = :object_type
"
set main_table_name $table_name
set main_id_column $id_column
# ******************************************************
# Create the list of all attributes of the current type
# ******************************************************

set dbi_interfaces ""
set dbi_inserts ""
set dbi_procs ""
# ------------------------------------------
# check if this object type have interface
# information to be generated
# ------------------------------------------
set generate_interfaces 0

set show_hidde_link "<a href=\"?[export_vars -base {} -url -override {{show_interfaces_p 0}} {object_type orderby show_interfaces_p}]\"> [_ intranet-dynfield.Hide_interfaces]</a>"


db_multirow attributes attributes_query {} {
    if {[empty_string_p $table_name]} {
	set table_name $main_table_name
	set id_column $main_id_column
    } else {
	db_1row "get id_column" "select id_column 
			from acs_object_type_tables 
			where object_type = :object_type 
			and table_name = :table_name"
    }
}



# ******************************************************
# Create the list of all attributes of the current type
# ******************************************************

set extension_tables_query "
    select 
	ott.*
    from 
	acs_object_type_tables ott
    where 
	ott.object_type = :object_type
"

db_multirow extension_tables extension_tables_query $extension_tables_query

ad_return_template
