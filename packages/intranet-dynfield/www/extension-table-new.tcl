ad_page_contract {

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id: extension-table-new.tcl,v 1.3 2006/04/07 23:07:39 cvs Exp $
} {
    object_type
    {table_name ""}
    return_url
    {form_mode "edit"}
}

# ******************************************************
# Initialization, defaults & security
# ******************************************************

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

acs_object_type::get -object_type $object_type -array "object_info"

set title "Add Extension Table to $object_info(pretty_name)"
set context [list [list "/intranet-dynfield/" DynField] [list "/intranet-dynfield/object-types" "Object Types"] [list "object-type?object_type=$object_type" $object_info(pretty_name)] $title]


# ******************************************************
# Build the form
# ******************************************************

set action_url "extension-table-new-2"

ad_form \
    -name extension_table_form \
    -cancel_url $return_url \
    -action $action_url \
    -mode $form_mode \
    -export {object_type return_url} \
    -form {

	{table_name:text(text) {label "Table Name"} {html {size 40}}}
	{id_column:text(text) {label "ID Column"} {html {size 40}}}
    }

ad_form -extend -name extension_table_form  -select_query {

        select  w.*
        from    im_dynfield_widgets w
        where   w.widget_id = :widget_id

}

    
ad_return_template
