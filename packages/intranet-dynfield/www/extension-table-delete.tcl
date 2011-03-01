ad_page_contract {

    @author Frank Bergmann frank.bergmann@project-open.com
    @creation-date 2005-01-05
    @cvs-id $Id: extension-table-delete.tcl,v 1.3 2006/04/07 23:07:39 cvs Exp $

} {
    object_type
    extension_tables:multiple
    return_url
}

# ******************************************************
# Default & Security
# ******************************************************

set title "Delete Extension Tables"
set context [list $title]

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

# ******************************************************
# Check if you can delete all Extension_Tables
# ******************************************************
set child_record_found 0
set explanation_text ""
if {[info exists extension_tables]} {

    foreach extension_table $extension_tables {
	if {0 < [db_string attributes_table "
		select 
			count(*)
		from	acs_attributes
		where 	object_type = :object_type
			and table_name = :extension_table
		"]} {
		incr child_record_found
		append explanation_text "<li> [_ intranet-dynfield.You_can_t_remove_table_explanation]</li>\n"
    	}
    }
}

if {0 < $child_record_found} {
	ad_return_complaint "$child_record_found" "$explanation_text"
	return
}

# ******************************************************
# Create the list of Extension_Tables
# ******************************************************

if {[info exists extension_tables]} {

    foreach extension_table $extension_tables {
	db_dml delete_extension_table "
	delete 
	from	acs_object_type_tables
	where 	object_type = :object_type
		and table_name = :extension_table
	"
    }

}

ad_returnredirect $return_url
