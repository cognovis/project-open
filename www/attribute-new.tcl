ad_page_contract {

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$
} {
    {object_type ""}
    {attribute_id 0}
    attribute_name:optional
    {acs_attribute_id 0}
    {required_p "f"}
    {modify_sql_p "f"}
    {action ""}
    {label_style "plain" }
}

# ******************************************************
# Initialization, defaults & security
# ******************************************************

ns_log Notice "attribute-new: attribute_id=$attribute_id, acs_attribute_id=$acs_attribute_id"
set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "[_ intranet-dynfield.You_have_insufficient_privileges_to_use_this_page]"
    return
}


# Check the arguments: Either object_type or attribute_id
# need to be specified
if {0 != $acs_attribute_id} {
    set attribute_id [db_string attribute_id "
	select attribute_id 
	from im_dynfield_attributes 
	where acs_attribute_id=:acs_attribute_id
    " -default "acs_object"]
}

if {0 != $attribute_id} {
    db_1row attribute_info "
    select
	a.object_type,
	a.pretty_name,
	a.pretty_plural,
	a.attribute_name,
	a.table_name,
	case when a.min_n_values = 0 then 'f' else 't' end as required_p,
    	fa.widget_name,
	fa.include_in_search_p,
	fa.also_hard_coded_p,
	dl.pos_x, dl.pos_y,
	dl.size_x, dl.size_y,
	dl.label_style, dl.div_class
    from 	
	acs_attributes a,
    	im_dynfield_attributes fa
	LEFT OUTER JOIN
		(select * from im_dynfield_layout where page_url = 'default') dl
		ON (fa.attribute_id = dl.attribute_id)
    where
	fa.attribute_id = :attribute_id
    	and fa.acs_attribute_id = a.attribute_id
    "
    set element_mode "view"
} else {
    set element_mode "edit"
}

if {"" == $label_style} { set label_style "plain" }

if {[empty_string_p $object_type]} {
    ad_return_complaint 1 "[_ intranet-dynfield.No_object_type_found]<br>
    [_ intranet-dynfield.You_need_to_specifiy_either_the_object_type_or_an_attribute_id]"
    return
}

acs_object_type::get -object_type $object_type -array "object_info"

if {![exists_and_not_null table_name]} {
   set table_name [db_string table_name "
	select table_name 
	from acs_object_types 
	where object_type=:object_type
    " -default ""]
}
if {[string equal $action "already_existing"]} {
    set title "[_ intranet-dynfield.Add_Attribute]"
} else {
    set title "[_ intranet-dynfield.Add_a_completely_new_attribute_modify_DB]"
}
set context [list [list objects Objects] [list "object-type?object_type=$object_type" $object_info(pretty_name)] "[_ intranet-dynfield.Add_Attribute]"]


# ******************************************************
# Determine all fields in the table that 
# haven't been added yet
# ******************************************************

set all_tables_sql "
	select distinct table_name 
	from acs_object_type_tables 
	where object_type=:object_type
"

# Get the attributes from all extension tables
set all_attributes [list]
#set all_tables [list $table_name]
set all_ext_tables [db_list all_extension_tables $all_tables_sql]
set all_tables [linsert $all_ext_tables 0 $table_name]
#if {[llength $all_ext_tables]>0} {
#	set all_tables [concat $all_tables $all_ext_tables]
#}


foreach table_n $all_tables {
    set table_columns [db_columns $table_n]

    foreach col $table_columns {
	lappend all_attributes "$table_n:$col"
    }
}

set existing_attributes [db_list existing_attributes "
	select
		attribute_name 
	from
		acs_attributes a,
		im_dynfield_attributes fa
	where 
		a.object_type=:object_type
		and a.attribute_id = fa.acs_attribute_id
"]

# Get the list of all "ID Columns" in order to exclude
# them from the list of fields
set id_columns {}

set main_table_name $object_info(table_name)
set main_id_column $object_info(id_column)
set extension_table_options [list]

# Show the list of extension tables
# plus the main object's table
set extension_tables_sql "
	select
		table_name as table_n, 
		id_column as id_c
	from
		acs_object_type_tables 
	where
		object_type = :object_type
    UNION
	select
		:main_table_name as table_n,
		:main_id_column as id_c
"
db_foreach extension_tables $extension_tables_sql {

    # Add the table as a table belonging to this object
    lappend extension_table_options [list $table_n $table_n]

    # Store the ID column information in order to exclude them
    # from the list of selectable fields
    lappend id_columns "$table_n:$id_c"

}

# Only add attributes that don't exist yet
set attribute_name_options {}
foreach attr $all_attributes {

    if {[lsearch $existing_attributes $attr] >= 0} { continue }

    if {[lsearch $id_columns $attr] >= 0} { continue }
    lappend attribute_name_options [list $attr $attr]

}



# ******************************************************
# Build the list of form fields. 
# attribute_name can be a textbox or a drop-down,
# depending on whether we want to add a new field
# or an existing one.
# ******************************************************

set form_fields {
    {attribute_id:key}
}

# Completely new attribute or
# modify an already existing attribute?
if {[string equal $action "already_existing"]} {
    
    lappend form_fields {attribute_name:text(select) {label {Attribute Name}} {options $attribute_name_options} {help_text "<!<li><a href=\"attribute-new?object_type=$object_type&action=completely_new\">[_ intranet-dynfield.lt_Add_a_completely_new_]</a>"}}
    set modify_sql_p "f"
    lappend form_fields {modify_sql_p:text(hidden) {value $modify_sql_p}}

} else {

    lappend form_fields {
	attribute_name:text 
	{label {<nobr>Attribute Name</nobr>}} 
	{html {size 30 maxlength 100}} 
	{mode $element_mode} 
	{help_text "
		This name becomes a column name in the database and a local variable. 
		Please only choose lower case characters and use underscore ('_') instead of spaces.
		Please use the suffix '_id' (for example: 'project_id') if the field references another table
		and stick to the general conventions for variable names.
	"}
    }

    lappend form_fields {
	table_name:text(select) 
	{label {Table Name}} 
	{options $extension_table_options } 
	{mode $element_mode} 
	{help_text "
		Select the database table where to add the new column.
		Usually there is only a single table per object, so there isn't much choice.
	"}
    }

    set modify_sql_p "t"
    lappend form_fields {modify_sql_p:text(hidden) {value $modify_sql_p}}

}

lappend form_fields {
	action:text(hidden),optional 
	{}
}

lappend form_fields {
	pretty_name:text 
	{label {Pretty Name}} 
	{html {size 30 maxlength 100}}
	{help_text "This is the default name that will appear as a label for the new field in forms."}
}

lappend form_fields {
	pretty_plural:text 
	{label {Pretty Plural}} 
	{html {size 30 maxlength 100}}
	{help_text "Just put the same as Pretty Name"}
}
lappend form_fields {
	required_p:text(radio) 
	{label {Required}} 
	{options {{Yes t} {No f}}} 
	{value $required_p}
	{help_text "Should the user be required to specifiy this field?"}
}
lappend form_fields {object_type:text(hidden) {label {Object Type}} {} {html {size 30 maxlength 100}}  }
lappend form_fields {
	widget_name:text(select) 
	{label Widget} 
	{options $widget_options } 
	{help_text "
		Specify the value range of the attribute. There is a <a href=widgets>widgets gallery</a> 
		available to show the available widgets.
	"}
}
lappend form_fields {
	also_hard_coded_p:text(radio)
	{label {<nobr>Also Hard Coded?</nobr>}} 
	{options {{Yes t} {No f}}} 
        {help_text "
		Does this field also exist hard coded in the PO-screens?
		Set this field if it should not appear in PO screens.
        "}
}
lappend form_fields {pos_x:text(hidden),optional {label {Pos-X}} {html {size 5 maxlength 4}}}
lappend form_fields {
	pos_y:text,optional 
	{label {Pos-Y}} 
	{html {size 5 maxlength 4}}
	{help_text "
		Give a value for the Y-position, ranging from '0' (top)	to '100' (bottom). 
		Currently, DynFields are appended at the end of any form in the order given
		by this variable.
	"}
}
lappend form_fields {size_x:text(hidden),optional {label {Size-X}} {html {size 5 maxlength 4}}}
lappend form_fields {size_y:text(hidden),optional {label {Size-Y}} {html {size 5 maxlength 4}}}
lappend form_fields {label_style:text(hidden) {label {Label Style}} {options {{Plain plain} {{No Label} no_label} }} {value $required_p}}
lappend form_fields {
	include_in_search_p:text(checkbox) 
	{label {<nobr>Include in Search?</nobr>}} 
	{options {{Yes t}}} 
	{value $required_p}
}


# ******************************************************
# Build the form
# ******************************************************

set widget_options " [db_list_of_lists select_widgets { 
	select 
		fw.widget_name, 
		fw.widget_name 
	from 
		im_dynfield_widgets fw
	order by 
		fw.widget_name 
} ]"

# For using the pretty_name we need to apply lang::util::localize
# lappend widget_options [list [lang::util::localize $pretty_name] $widget_name]


ad_form -name attribute_form -form $form_fields -new_request {
} -edit_request {
} -validate {
    # Validation that the attribute isn't already in the database
    { attribute_name 
        { [::regexp -nocase {^([0-9]|[a-z]|\_|:){1,}$} $attribute_name match attribute_name_validate] } 
        "You have used invalid characters."
    }
    { attribute_name 
        { ![im_dynfield::attribute::exists_p -object_type object_type -attribute_name $attribute_name] } 
        "Attribute $attribute_name already exists for <a href=\"object-type?[export_vars -url {object_type}]\">$object_info(pretty_name)</a>."
    }
} -on_submit {
} -new_data {
} -edit_data {
    # Update information

    if {$required_p == "f"} {
	set min_n_values "0"
    } else {
	set min_n_values "1"
    }

    db_transaction {
	# update acs_attributes table
	db_dml "update acs_attributes" "
	    update acs_attributes set
		pretty_name = :pretty_name,
		pretty_plural = :pretty_plural,
		min_n_values = :min_n_values
	    where
		attribute_id = (
			select acs_attribute_id 
			from im_dynfield_attributes 
			where attribute_id = :attribute_id
		)
	"

	# update im_dynfield_attributes table
	db_dml "update im_dynfield_attributes" "
		update im_dynfield_attributes set
			widget_name = :widget_name,
			include_in_search_p = :include_in_search_p,
			also_hard_coded_p = :also_hard_coded_p
		where attribute_id = :attribute_id
	"
    }

    # Make sure there is a layout entry for this DynField
    set layout_exists_p [db_string layout_exists "select count(*) from im_dynfield_layout where attribute_id = :attribute_id and page_url = 'default'"]
    if {!$layout_exists_p && 0 != $attribute_id} {
	    db_dml insert_layout "
		insert into im_dynfield_layout (
			attribute_id, page_url, label_style
		) values (
			:attribute_id, 'default', :label_style
		)
	    "
    }

    db_dml update_layout "
		update im_dynfield_layout set
			pos_x = :pos_x,
			pos_y = :pos_y,
			size_x = :size_x,
			size_y = :size_y,
			label_style = :label_style
		where
			attribute_id = :attribute_id
			and page_url = 'default'
    "

} -after_submit {

    if {[regexp (.+):(.+) $attribute_name match t_name a_name]} {
    	set table_name $t_name
    	set attribute_name $a_name
    }

    ad_returnredirect "attribute-new-2?[export_vars -url {object_type widget_name attribute_name pretty_name table_name required_p modify_sql_p pretty_plural description}]"
    ad_script_abort

}

ad_return_template

