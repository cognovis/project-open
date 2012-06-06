ad_page_contract {

    @author Matthew Geddert openacs@geddert.com
    @author Frank Bergmann frank.bergmann@project-open.com
    @creation-date 2008-03-28
    @cvs-id $Id$

	@param object_type
		Defines the object to be created/saved

	@param group_ids 
		List of groups for the person to be added to.
		Groups are linked via categories (of the same name) to
		the DynField attributes to be shown.

	@param list_ids 
		List of object-subtypes for the im_company or im_office to 
		be created.
	
	@param object_types
		List of objects to create using this page. We will also
		create a link between these object types.
		Example: im_company + person => + company-person-membership
} {
    party_id:optional
    {object_type ""}
    {list_names ""}
    {rel_type ""}
    {role_two ""}
    {object_id_two ""}
    {return_url ""}
} -validate {
    valid_type -requires {object_type} {
	if { ![xotcl::Class isclass "[::im::dynfield::Class object_type_to_class ${object_type}]"] } {
	    ad_complain "${object_type} [_ intranet-contacts.lt_You_have_not_specifie]"
	}
    }
}

# --------------------------------------------------
# Append the option to create a user who get's a welcome message send
# Furthermore set the title.

set title "[_ intranet-contacts.Add_a_${object_type}]"

set context [list $title]
set current_user_id [ad_get_user_id]


# --------------------------------------------------
# Environment information for the rest of the page
set package_id [ad_conn package_id]
set package_url [ad_conn package_url]
set user_id [ad_conn user_id]
set peeraddr [ad_conn peeraddr]

# --------------------------------------------------
# Append relationship attributes

if {[exists_and_not_null role_two]} {
    set rel_type [db_string select_rel_type "select rel_type from contact_rel_types where secondary_object_type = :object_type and secondary_role = :role_two" -default ""]
    if {$rel_type == ""} {
	set rel_type [db_string select_rel_type "select rel_type from contact_rel_types where secondary_object_type = 'party' and secondary_role = :role_two" -default ""] 
    }
}

set class "[::im::dynfield::Class object_type_to_class ${object_type}]"

if {[exists_and_not_null party_id] && [acs_object::object_p -id $party_id]} {
    set party [::im::dynfield::Class get_instance_from_db -id $party_id]
    set class [$party class]
} else {
    set party [$class create ::party ]
    $party set object_type $object_type
}

set list_ids [$party list_ids]
if {[exists_and_not_null rel_type]} {
    lappend list_ids [ams::list::get_list_id  -object_type "$rel_type" -list_name "$rel_type"]
}

set form [::im::dynfield::Form create ::im_company_form -class "$class" -list_ids $list_ids -name "party_ae" -data $party -key "party_id" -submit_link "/intranet-contacts/contact"  -export [list [list rel_type $rel_type] [list object_id_two $object_id_two] [list role_two $role_two]]]

$form generate

ad_return_template
