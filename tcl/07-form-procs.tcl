ad_library {
  A simple OO interface for ad_form for dynfield objects.

  @author Gustaf Neumann
  @creation-date 2005-08-13
  @cvs-id $Id$
}

# Get the OpenACS version
set ver_sql "select substring(max(version_name),1,3) from apm_package_versions where package_key = 'acs-kernel'"
set openacs54_p [string equal "5.4" [util_memoize [list db_string ver $ver_sql ]]]

if {$openacs54_p} {

namespace eval ::im::dynfield {

    Class Form -parameter { 
        {data ""}
        {name {[namespace tail [self]]}}
        class
        list_ids
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

        my instvar data folder_id key class list_ids export object_type

        if {![exists_and_not_null class]} {return}
        if {![exists_and_not_null list_ids]} {
            set list_ids [$class default_list_id]
        }

        set form_elements [list [list ${key}:key]]
   
        foreach dynfield_id [::im::dynfield::Attribute dynfield_attributes -list_ids $list_ids] {
            set element [im::dynfield::Element get_instance_from_db -id [lindex $dynfield_id 0] -list_id [lindex $dynfield_id 1]]
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
        db_foreach object_types "select distinct object_type from acs_attributes aa, im_dynfield_attributes ida, im_dynfield_type_attribute_map tam where aa.attribute_id = ida.acs_attribute_id and ida.attribute_id = tam.attribute_id and tam.object_type_id in ([template::util::tcl_to_sql_list $list_ids])" {
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


::im::dynfield::Class get_class_from_db -object_type "im_company"

}

