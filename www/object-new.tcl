# packages/intranet-dynfield/attributes/object-new.tcl

ad_page_contract {

    Edit/Create an Object
    
    This pages allows to edit and create objects generically.
    It asumes that all (important) object fields are
    defined in acs_attributes and im_dynfield_attributes (SQL
    metadata).
    These metadata are used to generate the entries of
    a template form that handle the actual interaction
    such as the rendering of templates, validation and
    storage.

    @author mbryzek@arsdigita.com
    @author Frank Bergmann (frank.bergmann@project-open.com)

} {
    object_id:integer
    object_type
    { return_url "" }
}


# ------------------------------------------------------
# Initialization, security, defaults etc.
# ------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}


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

if {"" == $object_type_pretty_name} {
    ad_return_complaint 1 "Unknown object_type '$object_type'<br>
    We were unable to find the specified object type."
    return
}

set title "Add/Modify $object_type_pretty_name"
set context [list "$title"]
set form_id "add_object"
#set variable_prefix ""

# -------------------------------------------
# create a form
# -------------------------------------------

template::form create $form_id
		    
# -------------------------------------------
# create or extend form_id with im_dynfield_attributes
# -------------------------------------------

im_dynfield::append_attributes_to_form -object_type $object_type \
	-form_id $form_id \
	-object_id $object_id
	

# -------------------------------------------
# process de form
# -------------------------------------------

if {[template::form is_valid $form_id]} {
	if {![exists_and_not_null object_id]} {
	   # -------------------------------------------
	   # here you can create new objects
	   # -------------------------------------------
	}
	
	# -------------------------------------------
	# update intranet-dynfield values
	# -------------------------------------------
	im_dynfield::attribute_store -object_type $object_type -object_id $object_id -form_id $form_id
	template::forward "object-type?object_type=$object_type"
}



# ------------------------------------------------------
# We pass on to the ADP page to render the page
# ------------------------------------------------------



ad_return_template

