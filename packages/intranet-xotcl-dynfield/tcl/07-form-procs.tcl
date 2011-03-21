# packages/intranet-xo-dynfield/tcl/07-form-procs.tcl
#
# Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

ad_library {
  A simple OO interface for ad_form for dynfield objects.

  @author Gustaf Neumann
  @creation-date 2005-08-13
  @cvs-id $Id: 07-form-procs.tcl,v 1.3 2010/04/25 16:41:39 moravia Exp $
}

namespace eval ::im::dynfield {

    Class Form -parameter { 
        {data ""}
        {name {[namespace tail [self]]}}
        class
        object_type_ids
        {fields ""}
        {key "object_id"}
        add_page_title
        edit_page_title
        {validate ""}
        {html ""}
        {submit_link "."}
        {defaults ""}
        {object_types ""}
        {export ""}
        {datatype ""}
        } -ad_doc {
            Class for the simplified generation of forms. 
    
        <ul>
        <li><b>data:</b> data object (e.g. instance if im::dynfield::Object) 
        <li><b>name:</b> of this form, used for naming the template, 
       defaults to the object name
       <li><b>add_page_title:</b> page title when adding content items
       <li><b>edit_page_title:</b> page title when editing content items
       <li><b>submit_link:</b> link for page after submit
       </ul>
    }
  
    Form instproc init {} {
        set level [template::adp_level]
        my forward var uplevel #$level set 

        my instvar data folder_id key class object_type_ids export object_type

        if {![exists_and_not_null class]} {return}
        if {![exists_and_not_null object_type_ids]} {
            set object_type_ids [$class default_object_type_id]
        }

        set form_elements [list [list ${key}:key]]
   
        foreach dynfield_id [::im::dynfield::Attribute dynfield_attributes -object_type_ids $object_type_ids] {
            set element [im::dynfield::Element get_instance_from_db -id [lindex $dynfield_id 0] -object_type_id [lindex $dynfield_id 1]]
            set form_elements [concat $form_elements [$element form_element]]
            set datatype([$element attribute_name]) [$element datatype]
            set defaults([$element attribute_name]) [$element default_value]
        }
    
        if {[catch {set object_name [$data set name]}]} {set object_name ""}
        set exports [list object_type]
    
        if {[info exists export]} {foreach pair $export {
            lappend exports $pair
        }}
        
        foreach export_pair $exports {
            set form_elements [concat $form_elements "[lindex $export_pair 0]:text(hidden),optional"]
            set defaults([lindex $export_pair 0]) [lindex $export_pair 1]
        }
        
        my set fields $form_elements
        my set defaults [array get defaults]
        my set datatype [array get datatype]
        
        if {![my exists add_page_title]} {
            my set add_page_title [_ xotcl-core.create_new_type \
                                 [list type [$class pretty_name]]]
        }

        if {![my exists edit_page_title]} {
            my set edit_page_title [_ xotcl-core.edit_type \
                                  [list type [$class pretty_name]]]
        }
        
        set object_types [list]
        db_foreach object_types "select distinct object_type from acs_attributes aa, im_dynfield_attributes ida, im_dynfield_type_attribute_map tam where aa.attribute_id = ida.acs_attribute_id and ida.attribute_id = tam.attribute_id and tam.object_type_id in ([template::util::tcl_to_sql_list $object_type_ids])" {
            lappend object_types $object_type
            my mixin "[::im::dynfield::Form object_type_to_class $object_type]"
        }
        my set object_types $object_types
        
        # We now need to make sure that the object_types we have are linked using realtionships.
        # Therefore check for a relationship list.
    }
  
    Form instproc form_vars {} {
        set vars [list]
        foreach varspec [my fields] {
            lappend vars [lindex [split [lindex $varspec 0] :] 0]
        }
        return $vars
    }
  
    Form instproc new_data {} {
        my instvar data key
        my log "--- new_data ---"
        foreach __var [my form_vars] {
            if {![regexp "(.*?)__(.*?)" $__var match object_type attribute_name]} {
                set attribute_name $__var
                set object_type ""
            } else {
                # I have no idea why the above regexp does not work....
                # So we need to do it again .....
                regexp "${object_type}__(.*)" $__var match attribute_name
            }
            $data set $attribute_name [my var $__var]
            my log "-- $attribute_name :: [$data set $attribute_name]"
        }
        $data set object_id [$data set $key]
	$data set object_type [$data set object_type]
        $data initialize_loaded_object
        $data save_new
        return [$data set object_id]
    }
 
    Form instproc edit_data {} {
        #my log "--- edit_data --- setting form vars=[my form_vars]"
        my instvar data
        foreach __var [my form_vars] {
            if {![regexp "(.*?)__(.*?)" $__var match object_type attribute_name]} {
                set attribute_name $__var
                set object_type ""
            } else {
                # I have no idea why the above regexp does not work....
                # So we need to do it again .....
                regexp "${object_type}__(.*)" $__var match attribute_name
            }
            $data set $attribute_name [my var $__var]
        }
        $data initialize_loaded_object
    
        $data save
        return [$data set object_id]
    }

    Form instproc request {privilege} {
        my instvar edit_form_page_title context data

        set edit_form_page_title [if {$privilege eq "create"} \
		    {my add_page_title} {my edit_page_title}]

        set context [list $edit_form_page_title]
    }

    Form instproc new_request {} {
        my log "--- new_request ---"
        my request create
        my instvar class key
        array set defaults [my defaults]
        foreach var [$class array names db_slot] {
            if {[exists_and_not_null defaults($var)]} {
                my set var $defaults($var)
            }
        }
    }
  
    Form instproc edit_request {} {
        my instvar data
        my request write
        foreach __var [my form_vars] {
            if {![regexp "(.*?)__(.*?)" $__var match object_type attribute_name]} {
                set attribute_name $__var
                set object_type ""
            } else {
                # I have no idea why the above regexp does not work....
                # So we need to do it again .....
                regexp "${object_type}__(.*)" $__var match attribute_name
            }
            if {[$data exists $attribute_name]} {
                set value [$data set $attribute_name]
                array set datatype [my datatype]
                if {[exists_and_not_null datatype($attribute_name)]} {
                    if {$datatype($attribute_name) eq "date"} {
                        set value [split $value "-"]
                    }
                } else {
                    ns_log Error "No datatype for $attribute_name"
                }
                my var $__var [list $value]
            }
        }
    }

    Form instproc on_submit {} {
        # The content of this proc is strictly speaking not necessary.
        # However, on redirects after a submit to the same page, it
        # ensures the setting of edit_form_page_title and context
        my request write
    }

    Form instproc on_validation_error {} {
        my instvar edit_form_page_title context
        my log "-- "
        set edit_form_page_title [my edit_page_title]
        set context [list $edit_form_page_title]
    }
  
    Form instproc after_submit {} {
        my instvar data object_id key
        set link [my submit_link]
        set value [$data set object_id]
        set link [export_vars -base "$link" -url [list [list "$key" "$value"]]]
        ad_returnredirect $link
        ad_script_abort
    }
 
    Form ad_instproc generate {
        {-template "formTemplate"}
    } {
        the method generate is used to actually generate the form template
        from the specifications and to set up page_title and context 
        when appropriate.
        @template is the name of the tcl variable to contain the filled in template
    } {
        # set form name for adp file
        my set $template [my name]
        my instvar data form_vars
        if {[catch {set object_name [$data set name]}]} {set object_name ""}
        my log "-- $data, cl=[$data info class] [[$data info class] object_type]"
    
        my log "--e [my name] final fields [my fields] :: [my form_vars]"
    
        ad_form -name [my name] -form [my fields] -html [my html]

        set new_data            "set item_id \[[self] new_data\]"
        set edit_data           "set item_id \[[self] edit_data\]"
        set new_request         "[self] new_request"
        set edit_request        "[self] edit_request"
        set after_submit        "[self] after_submit"
        set on_validation_error "[self] on_validation_error"
        set on_submit           "[self] on_submit"

        # action blocks must be added last
        ad_form -extend -name [my name] \
            -validate [my validate] \
            -new_data $new_data -edit_data $edit_data -on_submit $on_submit \
            -new_request $new_request -edit_request "$edit_request" \
            -on_validation_error $on_validation_error -after_submit $after_submit
    }
  
    Form proc object_type_to_class {name} {
        switch -glob -- $name {
            acs_object       {return ::im::dynfield::Form}
            content_revision {return "::im::dynfield::Form"}
            ::*              {return ::im::dynfield::Form::[namespace tail $name]}
            default          {return ::im::dynfield::Form::$name}
        }
    }
    
    Form ad_proc get_class_from_db {
        -object_type
    } {
       Fetch an acs_object_type from the database and create
       an XOTcl Form class from this information.

       The XOTcl class is dynfield enabled

       @return class name of the created XOTcl class. This is in the ::im::dynfield realm
     } {
         
         db_1row dbqd..fetch_class {
           select object_type, supertype, pretty_name, lower(id_column) as id_column, lower(table_name) as table_name
           from acs_object_types where object_type = :object_type
         }

         set classname [my object_type_to_class "$object_type"]
         # Check if the supertype class exists and if not, create it.
         # This works recursive
         if {$supertype ne "acs_object" && ![my isclass [my object_type_to_class "$supertype"]]} {
             my get_class_from_db -object_type "$supertype"
         }
         
         if {![my isclass $classname]} {
             ::xotcl::Class create $classname \
                 -superclass [my object_type_to_class $supertype] \
                 -ad_doc "This is the specific Form class for the object type ${object_type} and allows manipulation of the on_submit etc. blocks for this object_type when ::im::dynfield::Form generate is called. Obviously if you know your      object_type you could just as well call this Class."
         }
    }
}


# Add render_label element to get element labels in dynamic forms (works with flextag-init)
namespace eval template::element {}

ad_proc -private template::element::render_label { form_id element_id tag_attributes } {
    Render the -label text

    @param form_id	The identifier of the form containing the element.
    @param element_id     The unique identifier of the element within the form.
    @param tag_attributes Reserved for future use.
} {
  get_reference

  return $element(label)
}



ad_proc -public im_dynfield::form {
    -object_type:required
    -form_id:required
    -object_id:required
    -return_url:required
    {-page_url ""}
} {
    Returns a fully formatted template, similar to ad_form.
    As a difference to ad_form, you don't need to specify the
    fields of the object, because they are defined dynamically
    in the intranet-dynfield database.
    Please see the Intranet-Dynfield documentation for more details.
} {
    eeerror
    if { [empty_string_p $page_url] } {
	# get default page_url
	set page_url [db_string get_default_page {
	    select page_url
	    from im_dynfield_layout_pages
	    where object_type = :object_type
	    and default_p = 't'
	} -default ""]
    }

    
    # verify correctness of page_url if something wrong just ignore dynamic position
    if { [db_0or1row exists_page_url_p "select 1 from im_dynfield_layout_pages
	where object_type = :object_type and page_url = :page_url"]
    } {
	set layout_page_p 1
    } else {
	set layout_page_p 0
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
    
    # check if this object_type involve more tables
    # get object_type tables tree
    set obj_type $object_type
    set object_type_tables [list]
    while {$obj_type != "acs_object"} {

	set obj_type_tables [db_list "get tables related to object_type" "
		select distinct table_name 
		from acs_attributes 
		where object_type = :obj_type 
		and table_name is not null
	"]
	db_1row "get obj_type table" "select table_name as t, supertype as obj_type \
	    from acs_object_types \
	    where object_type = :obj_type"
	lappend obj_type_tables $t
	foreach table $obj_type_tables {

	    if {[lsearch -exact $object_type_tables $table] == -1} {
		lappend object_type_tables $table
	    }
	}

    }

    foreach t_name $object_type_tables {
	# get the primary key for all tables related to object type
    
	db_1row "get table pk" "
	select COLUMN_NAME as c_id
	FROM ALL_CONS_COLUMNS \
	WHERE 
		TABLE_NAME = UPPER(:t_name) \
		AND CONSTRAINT_NAME = ( SELECT CONSTRAINT_NAME \
		FROM ALL_CONSTRAINTS \
		WHERE TABLE_NAME = UPPER(:t_name) \
		AND CONSTRAINT_TYPE = 'P')"
    
	lappend object_type_tables_colid_list [list $t_name $c_id]
    }

    # ------------------------------------------------------
    # Create the form
    # ------------------------------------------------------
    
    # Create a new blank form.
    #
    template::form create $form_id


    # ------------------------------------------------------
    # Retreive object information 
    # OR:
    # Setup form to create a new object
    # ------------------------------------------------------

    if { [template::form is_request $form_id] } {

	if {[info exists object_id]} {
	    # get values from all tables related to object_type
	    foreach table_pair $object_type_tables_colid_list {
		set table_n [lindex $table_pair 0]
		set column_i [lindex $table_pair 1]

		# We can use a wildcard ("p.*") to select all columns from 
		# the object or from its extension table in order to get
		# values that might be added for a specific customer
		db_1row info "
			select 	o.*
			from	$table_n o
			where	o.$column_i = :object_id
		"
	    }


	} else {
	    
	    # Setup the form with an id_column field in order to
	    # create a new object of the given type

	    set object_id [db_nextval "acs_object_id_seq"]
	}
    }


    # ------------------------------------------------------
    # Create form elements from the "im_dynfield_attributes" 
    # table
    # ------------------------------------------------------

    # The table "im_dynfield_attributes" contains the list of
    # "attributes" (= fields or columns) of an object.
    # We are going to add these fields to the current view/
    # edit template.
    #
    # There is a special treatment for attribute "parameters".
    # These parameters are are passed on to the TCL widget
    # that renders the specific attribute value.


    # Pull out all the attributes up the hierarchy from this object_type
    # to the $object_type object type
    set attributes_sql "
	select a.attribute_id,
	       a.table_name as attribute_table_name,
	       a.attribute_name,
	       at.pretty_name,
	       a.datatype, 
	       case when a.min_n_values = 0 then 'f' else 't' end as required_p, 
	       a.default_value, 
	       t.table_name as object_type_table_name, 
	       t.id_column as object_type_id_column,
	       aw.widget,
	       aw.parameters,
	       at.table_name as attribute_table,
	       at.object_type as attr_object_type
	  from
	  	acs_object_type_attributes a, 
	  	im_dynfield_attributes aa,
	  	im_dynfield_widgets aw,
	  	acs_attributes at,
		acs_object_types t
	 where 
	 	a.object_type = :object_type
	 	and t.object_type = a.ancestor_type 
	 	and a.attribute_id = aa.acs_attribute_id
	 	and a.attribute_id = at.attribute_id
	 	and aa.widget_name = aw.widget_name
	 order by 
	 	attribute_id
    "

    db_foreach attributes $attributes_sql {
	# Might translate the datatype into one for which we have a
	# validator (e.g. a string datatype would change into text).
	set translated_datatype [attribute::translate_datatype $datatype]
	    
	set parameter_list [lindex $parameters 0]

	# Find out if there is a "custom" parameter and extract its value
	set custom_parameters ""
	set custom_pos [lsearch $parameter_list "custom"]
	if {$custom_pos >= 0} {
	    set custom_parameters [lindex $parameter_list [expr $custom_pos + 1]]
	}

	set html_parameters ""
	if {[string equal [lindex $parameter_list 0] "html"]} {
	    set html_parameters [lindex $parameter_list 1]
	}


	set value $default_value
	if {[info exists $attribute_name]} {
	    set value [expr "\$$attribute_name"]
	}

	if { [string eq $widget "radio"] || [string eq $widget "select"] || [string eq $widget "multiselect"]} {

	    # For enumerations, we generate a list all the possible values
	    set option_list [db_list_of_lists select_enum_values {
		select enum.pretty_name, enum.enum_value
		from acs_enum_values enum
		where enum.attribute_id = :attribute_id 
		order by enum.sort_order
	    }]
	    	    
	    if { [string eq $required_p "f"] } {
		# This is not a required option list... offer a default
		lappend option_list [list " (no value) " ""]
	    }
	    template::element create $form_id "$attribute_name" \
		    -datatype "text" [ad_decode $required_p "f" "-optional" ""] \
		    -widget $widget \
		    -options $option_list \
		    -label "$pretty_name" \
		    -value $value \
		    -custom $custom_parameters
	} else {
	
	    # ToDo: Catch errors when the variable doesn't exist
	    # in order to create reasonable error messages with
	    # object, object_type, expected variable name and the
	    # list of currently existing variables.
		
	    template::element create $form_id "$attribute_name" \
		    -datatype $translated_datatype [ad_decode $required_p "f" "-optional" ""] \
		    -widget $widget \
		    -label $pretty_name \
		    -value  $value\
		    -html $html_parameters \
		    -custom $custom_parameters
	}
    }
    

    # ------------------------------------------------------
    # Execute this for a "request" (= this page creates a HTML form)
    # In this case we pass some more parameters on to the form
    # ------------------------------------------------------

    if { [template::form is_request $form_id] } {
	
	# A list of additional variables to export
	set export_var_list [list object_id object_type]

	foreach var $export_var_list {
	    template::element create $form_id $var \
		    -value [set $var] \
		    -datatype text \
		    -widget hidden
	}
    }


    # ------------------------------------------------------
    # Store values if the form was valid
    # ------------------------------------------------------

    if { [template::form is_valid $form_id] } {

	set object_exists [db_string object_exists "select count(*) from $table_name where $id_column=:object_id"]

	if {!$object_exists} {
	    # We would have to insert a new object - 
	    # not implmeneted yet
	    ad_return_complaint 1 "Creating new objects not implmented yet<br>
	    Please create the object first via an existing maintenance screen
	    before using the Intranet-Dynfield generic architecture to modify its fields"
	    return
	}

	# check if exist entry in all relates object_type tables
	foreach table_pair $object_type_tables_colid_list {
	    set table_n [lindex $table_pair 0]
	    set column_i [lindex $table_pair 1]
	    if {$table_n != $table_name} {
		set extension_exist [db_string object_exists "select count(*) from $table_n where $column_i=:object_id"]
		if {!$extension_exist} {
		    # todo : create it
		    # mandatory fields!!!!!!!
		}

	    }
	}


	# Build the update_list for all attributes except $id_column
	#
	# for all tables related to object_type
	foreach table_pair $object_type_tables_colid_list {
	    set table_n [lindex $table_pair 0]
	    set column_i [lindex $table_pair 1]
	    set update_sql($table_n) "update $table_n set"
	    set first($table_n) 1
	    set pk($table_n) "$column_i"
	}

	# Get the list of all variables of the last form
	set form_vars [ns_conn form]

	db_foreach attributes $attributes_sql {

	    if {[empty_string_p $attribute_table]} {
		db_1row "get attr object type table" "
		    select table_name as attribute_table \
		    from acs_object_types \
		    where object_type = :attr_object_type"
	    }
	    # Skip the index column - it doesn't need to be
	    # stored.
	    if {[string equal $attribute_name $pk($attribute_table)]} { continue }
	    if {!$first($attribute_table)} { append update_sql($attribute_table) "," }

	    # Get the value of the form variable from the HTTP form
	    set value [ns_set get $form_vars $attribute_name]

	    # Store the attribute into the local variable frame
	    # We take the detour through the local variable frame
	    # (form ns_set -> local var frame -> sql statement)
	    # in order to be able to use the ":var_name" notation
	    # in the dynamically created SQL update statement.
	    set $attribute_name $value

	    append update_sql($attribute_table) "\n\t$attribute_name = :$attribute_name"
	    set first($attribute_table) 0
	}

	foreach table_pair $object_type_tables_colid_list {
	    set table_n [lindex $table_pair 0]
	    append update_sql($table_n) "\nwhere $pk($table_n) = :object_id\n"
	    
	    db_transaction {
		if {$first($table_n) == 0} {
		    db_dml update_object $update_sql($table_n)
		}
	    }
	}

	# Add the original return_url as the last one in the list
	lappend return_url_list $return_url
	
	set return_url_stacked [subsite::util::return_url_stack $return_url_list]

	ad_returnredirect $return_url_stacked
	ad_script_abort
    }
}

