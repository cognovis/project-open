ad_page_contract {

    @author Matthew Geddert openacs@geddert.com
    @author Frank Bergmann frank.bergmann@project-open.com
    @creation-date 2005-01-07
    @cvs-id $Id$
} {
    {object_type:notnull}
    {widget_name:notnull}
    {attribute_id 0}
    {attribute_name:notnull}
    {pretty_name:notnull}
    {pretty_plural:notnull}
    {table_name:notnull}
    {required_p:notnull}
    {modify_sql_p:notnull}
    {deprecated_p "f"}
    {include_in_search_p "f"}
    {also_hard_coded_p "f"}
    {datatype ""}
    {default_value ""}
    {description ""}
    {label_style ""}
    {pos_y "0"}
    {list_id ""}
    {return_url ""}
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

ns_log Notice "dynfield/attribute-new-2: object_type=$object_type, widget_name=$widget_name, attribute_id=$attribute_id, attribute_name=$attribute_name, pretty_name=$pretty_name, pretty_plural=$pretty_plural, table_name=$table_name, required_p=$required_p, modify_sql_p=$modify_sql_p, deprecated_p=$deprecated_p, datatype=$datatype, default_value=$default_value"

set attribute_id [im_dynfield::attribute::add \
		      -object_type $object_type \
		      -widget_name $widget_name \
		      -attribute_name $attribute_name \
		      -pretty_name $pretty_name \
		      -pretty_plural $pretty_plural \
		      -table_name $table_name \
		      -required_p $required_p \
		      -modify_sql_p $modify_sql_p \
		      -include_in_search_p $include_in_search_p \
		      -also_hard_coded_p $also_hard_coded_p \
		      -deprecated_p $deprecated_p \
		      -datatype $datatype \
		      -default_value $default_value \
		      -label_style $label_style \
		      -pos_y $pos_y \
		      -help_text "" \
		      -section_heading "" \
]

# ------------------------------------------------------------------
# Flush permissions
# ------------------------------------------------------------------

# Remove all permission related entries in the system cache
im_permission_flush



# ------------------------------------------------------------------
# Reload the class
# ------------------------------------------------------------------

set ttt {
upvar #0 object_type object_type2
set object_type2 $object_type
uplevel #0 {
    set class [::im::dynfield::Class object_type_to_class $object_type]
    $class destroy
    ::im::dynfield::Class get_class_from_db -object_type $object_type
}

}

# ------------------------------------------------------------------
#
# ------------------------------------------------------------------

set return_url "object-type?[export_vars -url {object_type}]"

if {$return_url == ""} {
    if {$list_id ne ""} {
        set return_url [export_vars -base "list" -url {list_id}]
    } else {
        set return_url "object-type?[export_vars -url {object_type}]"
    }
}


# If we're an enumeration, redirect to start adding possible values.
if { [string equal $datatype "enumeration"] } {
    ad_returnredirect enum-add?[ad_export_vars {attribute_id return_url}]
} elseif { [empty_string_p $return_url] } {
    ad_returnredirect add?[ad_export_vars {object_type}]
} else {
    ad_returnredirect $return_url
}
