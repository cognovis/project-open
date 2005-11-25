ad_page_contract {

    @author Juanjo Ruiz juanjoruizx@yahoo.es
    @creation-date 2005-02-07
    @cvs-id $Id$

} {
    object_type:notnull
    page_url:notnull
    orderby:optional
}

# ******************************************************
# Default & Security
# ******************************************************

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]

if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    ad_script_abort
}

set return_url "[ad_conn url]?[ad_conn query]"
set return_url_encoded [ns_urlencode $return_url]

acs_object_type::get -object_type $object_type -array "object_info"

set object_type_pretty_name $object_info(pretty_name)

set title "Attributes in $page_url"
set context [list [list "object-types" "Object Types"] [list "[export_vars -base "layout-manager" {object_type}]" "$object_type_pretty_name layout"] $title]

# ******************************************************
# List definition
# ******************************************************

db_1row get_layout_type {
    select layout_type, table_height, table_width
    from im_dynfield_layout_pages
    where object_type = :object_type
    and page_url = :page_url
} -column_array "page"

lappend action_list "Add attribute" "[export_vars -base "layout-position-2" { object_type page_url }]" "Add item to this order"
set no_data "[_ intranet-dynfield.No_attributes_added_to_this_page]"

set elements_list " pretty_name {
        label \"[_ intranet-dynfield.Attribute]\"
    }"

if { $page(layout_type) == "absolute" } {
    append elements_list " class {
	    label \"[_ intranet-dynfield.Class]\"
	    html { align center }
	}"
} elseif { $page(layout_type) == "relative" } {
    append elements_list " sort_key {
            label \"[_ intranet-dynfield.Sort_key]\"
            html { align center }
        }"
    set next_row [expr $page(table_width) + 1]
} elseif { $page(layout_type) == "adp" } {
    set elements_list ""
    ad_returnredirect [export_vars -base "layout-adp" {object_type page_url}]
}

append elements_list " attrib_edit {
        label \"\"
        display_template {
            <a href=\"@attrib_layout.edit_url@\" class=\"button\">#acs-kernel.common_Edit#</a>
        }
    }
    attrib_delete {
        label \"\"
        display_template {
            <a href=\"@attrib_layout.delete_url@\" class=\"button\">#acs-kernel.common_Delete#</a>
        }
    }"

list::create \
	-name attrib_list \
	-multirow attrib_layout \
	-key attribute_id \
	-actions $action_list \
	-no_data $no_data \
	-elements $elements_list \
	-orderby {
    pretty_name {orderby pretty_name}
    class {orderby class}
    sort_key {orderby sort_key}
} \
	-filters {
    object_type {}
    page_url {}
}

db_multirow -extend { edit_url delete_url } attrib_layout get_attributes "
    select aa.attribute_name, aa.pretty_name,  aa.pretty_plural, fl.class, fl.sort_key, fl.attribute_id
    from IM_DYNFIELD_LAYOUT fl, ACS_ATTRIBUTES aa, IM_DYNFIELD_ATTRIBUTES fa
    where fl.object_type = :object_type
    and fl.page_url = :page_url
    and aa.attribute_id = fa.acs_attribute_id
    and fl.attribute_id = fa.attribute_id
    [template::list::orderby_clause -name attrib_list -orderby]
" {
    set edit_url [export_vars -base "layout-position-2" { object_type page_url attribute_id }]
    set delete_url [export_vars -base "layout-position-del" { object_type page_url attribute_id }]
}

