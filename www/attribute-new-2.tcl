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


# ------------------------------------------------------------------
# 
# ------------------------------------------------------------------

acs_object_type::get -object_type $object_type -array "object_info"

set title "Define Options"
set context [list [list objects Objects] [list "object-type?object_type=$object_type" $object_info(pretty_name)] [list "attribute-add?object_type=$object_type" "Add Attribute"] $title]

db_1row select_widget_pretty_and_storage_type { 
	select	storage_type_id,
		im_category_from_id(storage_type_id) as storage_type
	from	im_dynfield_widgets 
	where	widget_name = :widget_name 
}

set user_message "Attribute <a href=\"attribute?[export_vars -url {attribute_id}]\">$pretty_name</a> Created."


# Get datatype from Widget or parameter if not explicitely given
if {"" == $datatype} {
    set datatype [db_string acs_datatype "
	select acs_datatype 
	from im_dynfield_widgets 
	where widget_name = :widget_name
    " -default "string"]
}

set attribute_name [string tolower $attribute_name]
set acs_attribute_exists [attribute::exists_p $object_type $attribute_name]
set im_dynfield_attribute_exists [im_dynfield::attribute::exists_p -object_type $object_type -attribute_name $attribute_name]

# Make sure there is an entry in acs_object_type_tables for the
# object type's main table. This table is needed by a RI constraint
# acs_attributes.

set ext_table_name $object_info(table_name)
set ext_table_id_column $object_info(id_column)
set extension_table_exists_p [db_string ext_table_exists "select count(*) from acs_object_type_tables where object_type = :object_type and table_name = :ext_table_name"]

if {!$extension_table_exists_p} {

    db_dml insert_table "
	    insert into acs_object_type_tables (
	        object_type,
	        table_name,
	        id_column
	    ) values (
	        :object_type,
	        :ext_table_name,
	        :ext_table_id_column
	    )
    "
}


# ------------------------------------------------------------------
# Create the attribute
# ------------------------------------------------------------------

set dynfield_attribute_id [im_dynfield::attribute::add \
			       -object_type $object_type \
			       -widget_name $widget_name \
			       -attribute_id $attribute_id \
			       -attribute_name $attribute_name \
			       -pretty_name $pretty_name \
			       -pretty_plural $pretty_plural \
			       -table_name $table_name \
			       -required_p $required_p \
			       -modify_sql_p $modify_sql_p \
			       -deprecated_p $deprecated_p \
			       -datatype $datatype \
			       -default_value $default_value \
			       -include_in_search_p $include_in_search_p \
			       -also_hard_coded_p $also_hard_coded_p \
			       -label_style $label_style \
			       -pos_y $pos_y \
]


# ------------------------------------------------------------------
# Map to the list
# ------------------------------------------------------------------

set list_id_sql "select distinct object_type_id from im_dynfield_type_attribute_map where attribute_id = :dynfield_attribute_id"
foreach list [db_list list_ids $list_id_sql] {
    im_dynfield::attribute::map -list_id $list_id -attribute_id $dynfield_attribute_id
    ::im::dynfield::Element flush -id $dynfield_attribute_id -list_id $list_id
}


# ------------------------------------------------------------------
# Set permissions for the dynfield so that it is visible by default
# ------------------------------------------------------------------

db_string emp_perms "select acs_permission__grant_permission(:attribute_id, [im_employee_group_id], 'read')"
db_string cust_perms "select acs_permission__grant_permission(:attribute_id, [im_customer_group_id], 'read')"
db_string freel_perms "select acs_permission__grant_permission(:attribute_id, [im_freelance_group_id], 'read')"

db_string emp_perms "select acs_permission__grant_permission(:attribute_id, [im_employee_group_id], 'write')"
db_string cust_perms "select acs_permission__grant_permission(:attribute_id, [im_customer_group_id], 'write')"
db_string freel_perms "select acs_permission__grant_permission(:attribute_id, [im_freelance_group_id], 'write')"



# ------------------------------------------------------------------
# Set all values of the object_type_map to "edit", so that the
# DynField is visible by default
# ------------------------------------------------------------------

set exists_p [db_string exists "
	select count(*) from im_dynfield_type_attribute_map 
	where attribute_id = :attribute_id and object_type_id = :object_type_id
"]
if {!$exists_p} {

    set type_category [im_dynfield::type_category_for_object_type -object_type $object_type]

    set cats_sql "
	select	category_id as object_type_id
	from	im_categories
	where	category_type = :type_category
    "
    db_foreach cats $cats_sql {
   
	db_dml insert "
		insert into im_dynfield_type_attribute_map (
			attribute_id,
			object_type_id,
			display_mode
		) values (
			:attribute_id,
			:object_type_id,
			'edit'
		)
	"
    }
}


# ------------------------------------------------------------------
# Reload the class
# ------------------------------------------------------------------

upvar #0 object_type object_type2
set object_type2 $object_type
uplevel #0 {
    set class [::im::dynfield::Class object_type_to_class $object_type]
    $class destroy
    ::im::dynfield::Class get_class_from_db -object_type $object_type
}


# ------------------------------------------------------------------
#
# ------------------------------------------------------------------

# set return_url "object-type?[export_vars -url {object_type}]"

if {$return_url eq ""} {
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
