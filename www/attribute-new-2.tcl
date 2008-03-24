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
    {datatype ""}
    {default_value ""}
    {description ""}
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

set return_url "object-type?[export_vars -url {object_type}]"
set user_message "Attribute <a href=\"attribute?[export_vars -url {attribute_id}]\">$pretty_name</a> Created."


# Get datatype from Widget or parameter if not explicitely given
if {"" == $datatype} {
    set datatype [db_string acs_datatype "
	select acs_datatype 
	from im_dynfield_widgets 
	where widget_name = :widget_name
    " -default "string"]
}


# Right now, we do not support number restrictions for attributes
set max_n_values 1
if { [string eq $required_p "t"] } {
    set min_n_values 1
} else {
    set min_n_values 0
}

set attribute_name [string tolower $attribute_name]
set acs_attribute_exists [attribute::exists_p $object_type $attribute_name]
set im_dynfield_attribute_exists [im_dynfield::attribute::exists_p -object_type $object_type -attribute_name $attribute_name]

# ad_return_complaint 1 "acs_attribute_exists=$acs_attribute_exists, im_dynfield_attribute_exists=$im_dynfield_attribute_exists"

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


# Add the attributes to the specified object_type
db_transaction {

    if {!$acs_attribute_exists} {

	    set acs_attribute_id [attribute::add_xt \
	    	-min_n_values $min_n_values \
	    	-max_n_values $max_n_values \
	    	-default $default_value \
	    	-modify_sql_p $modify_sql_p \
	    	-table_name $table_name \
	    	-attribute_name $attribute_name \
		-storage_type_id $storage_type_id \
	    	$object_type $datatype \
	    	$pretty_name $pretty_plural \
	    ]

	    # Distinguish between the table_name from acs_attributes
	    # and the table name in acs_objects.
	    # Only set the table_name in acs_attributes if it's different
	    # from the table in acs_objects.
	    if {$object_info(table_name) != $table_name} {
	    	db_dml "update acs_attribute table_name" "
	    		update acs_attributes 
	    		       set table_name = :table_name 
	    		where attribute_id = :acs_attribute_id"
	    }

    } else {

	set acs_attribute_id [db_string acs_attribute_id "
		select attribute_id 
		from acs_attributes 
		where 
			object_type = :object_type
			and attribute_name = :attribute_name"
	]
    }

    if {!$im_dynfield_attribute_exists} {

	# Let's create the new intranet-dynfield attribute
	# We're using exclusively TCL code here (not PL/PG/SQL
	# API).
	set attribute_id [db_exec_plsql create_object "
	    select acs_object__new (
                null,
                'im_dynfield_attribute',
                now(),
                '[ad_get_user_id]',
                null,
                null
	    );
        "]

	db_dml insert_im_dynfield_attributes "
            insert into im_dynfield_attributes
                (attribute_id, acs_attribute_id, widget_name, deprecated_p)
            values
                (:attribute_id, :acs_attribute_id, :widget_name, :deprecated_p)
        "
	
    } else {
    	
    }
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

set type_category [im_dynfield::type_category_for_object_type -object_type $object_type]
set cats_sql "
	select	category_id as object_type_id
	from	im_categories
	where	category_type = :type_category
"
db_foreach cats $cats_sql {
   
    set exists_p [db_string exists "
	select count(*) from im_dynfield_type_attribute_map 
	where attribute_id = :attribute_id and object_type_id = :object_type_id
    "]

    if {!$exists_p} {
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
#
# ------------------------------------------------------------------

# If we're an enumeration, redirect to start adding possible values.
if { [string equal $datatype "enumeration"] } {
    ad_returnredirect enum-add?[ad_export_vars {attribute_id return_url}]
} elseif { [empty_string_p $return_url] } {
    ad_returnredirect add?[ad_export_vars {object_type}]
} else {
    ad_returnredirect $return_url
}


#ad_return_template
