# /packages/mbryzek-subsite/www/admin/rel-types/role-new.tcl

ad_page_contract {
    Form to create a new role

    @author mbryzek@arsdigita.com
    @creation-date Mon Dec 11 10:52:35 2000
    @cvs-id $Id$
} {
    {role:trim "" }
    {pretty_name "" }
    {pretty_plural "" }
    {return_url "roles" }
} -properties {
    context:onevalue
}

set context [list [list "relationships" "[_ intranet-contacts.Relationship_types]"] [list "roles" "[_ intranet-contacts.Roles]"] "[_ intranet-contacts.Create_role]"]

ad_form -name "role_form" \
    -form {
	{return_url:text(hidden),optional}
	{role:text {label "[_ intranet-contacts.Role_Name]"}}
        {pretty_name:text {label "[_ intranet-contacts.Role_Singular]"}}
        {pretty_plural:text {label "[_ intranet-contacts.Role_Plural]"}}
    } -on_request {
	# if a return_url was provided it is set here
    } -on_submit {

	if {[db_string role_exists_with_same_names_p {
	    select count(r.role) from acs_rel_roles r where r.role = :role}]} {
	    ad_return_complaint 1 "[_ intranet-contacts.lt_li_The_role_you_enter]"
	    return
	}
	if { [empty_string_p $role] } {
	    rel_types::create_role -pretty_name $pretty_name -pretty_plural $pretty_plural
	} else {
	    rel_types::create_role -pretty_name $pretty_name -pretty_plural $pretty_plural -role $role
	}

    } -after_submit {
	ad_returnredirect $return_url
	ad_script_abort
    }

