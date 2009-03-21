ad_library {

	Classes for the elements and attributes
	
    @creation-date 2008-08-13
    @author  (malte.sussdorff@cognovis.de)
    @cvs-id 
}



##############################
#
# DynField Elements
#
##############################

xotcl::Class create ::im::dynfield::Element \
    -slots {
        xo::Attribute create attribute_name
        xo::Attribute create attribute_id -default 0
        xo::Attribute create dynfield_attribute_id
        xo::Attribute create object_type
        xo::Attribute create section_heading
        xo::Attribute create pretty_name
        xo::Attribute create pretty_plural
        xo::Attribute create datatype -default ""
        xo::Attribute create default_value -default ""
        xo::Attribute create min_n_values
        xo::Attribute create max_n_values
        xo::Attribute create column_name
        xo::Attribute create table_name
        xo::Attribute create widget_name
        xo::Attribute create required_p 
        xo::Attribute create widget_name
        xo::Attribute create required_p -default "f"
        xo::Attribute create modify_sql_p -default "f"
        xo::Attribute create include_in_search_p -default "f"
        xo::Attribute create also_hard_coded_p -default "f"
        xo::Attribute create deprecated_p -default "f"
        xo::Attribute create label_style -default "plain"
        xo::Attribute create sort_order -default "0"
        xo::Attribute create help_text -default ""
        xo::Attribute create list_id
        xo::Attribute create widget_id
        xo::Attribute create storage_type_id
        xo::Attribute create multiple_p
    } -ad_doc {
        Class for the Dynfield Elements. An Element is a combination of the attribute information from acs_attributes
        along with the information about the widget. This is list specific. For list unspecific things look at ::im::dynfield::Attribute
    }


::im::dynfield::Element ad_proc get_instance_from_db {
    -id:required 
    {-list_id ""}
} {
    Initialize a new Element object for an attribute. 
    
    @param id Dynfield Attribute ID
} {
    if {$list_id == ""} {
        # Apparently the list is not important, might be the case if the help_text is not needed or the default value
        set list_id [ams::list::get_id -attribute_id $id]
	if {"" == $list_id} { ad_return_complaint 1 "::im::dynfield::Element ad_proc get_instance_from_db: List_id is empty" }
    }
    set org_sql "
    select
           ida.attribute_id as dynfield_attribute_id,
           tam.section_heading,
           aa.attribute_id,
           aa.object_type,
           aa.attribute_name,
           aa.pretty_name,
           aa.pretty_plural,
           aa.datatype,
           aa.default_value,
           aa.min_n_values,
           aa.max_n_values,
           aa.column_name,
           aa.table_name,
           tam.required_p,
           ida.include_in_search_p,
           ida.also_hard_coded_p,
           ida.deprecated_p,
           idl.label_style,
           idl.pos_y as sort_order,
           ida.widget_name,
           tam.help_text,
           tam.object_type_id as list_id,
           tam.default_value,
           idw.widget_id,
           idw.storage_type_id
     from
           im_dynfield_attributes ida,
           acs_attributes aa,
           im_dynfield_type_attribute_map tam,
           im_dynfield_layout idl,
           im_dynfield_widgets idw
     where
           ida.acs_attribute_id = aa.attribute_id
           and tam.attribute_id = ida.attribute_id
           and ida.attribute_id = idl.attribute_id
           and ida.widget_name = idw.widget_name
           and ida.attribute_id = $id
           and tam.object_type_id = $list_id
     "
    
    # SQL without im_dynfield_layout.
    set sql "
    select
           ida.attribute_id as dynfield_attribute_id,
           tam.section_heading,
           aa.attribute_id,
           aa.object_type,
           aa.attribute_name,
           aa.pretty_name,
           aa.pretty_plural,
           aa.datatype,
           aa.default_value,
           aa.min_n_values,
           aa.max_n_values,
           aa.column_name,
           aa.table_name,
           tam.required_p,
           ida.include_in_search_p,
           ida.also_hard_coded_p,
           ida.deprecated_p,
           ida.widget_name,
           tam.help_text,
           tam.object_type_id as list_id,
           tam.default_value,
           idw.widget_id,
           idw.storage_type_id,
	   -- removed im_dynfield_layout because of multiple URLs
           'plain' as label_style,
           0 as sort_order
     from
           im_dynfield_attributes ida,
           acs_attributes aa,
           im_dynfield_type_attribute_map tam,
           im_dynfield_widgets idw
     where
           ida.acs_attribute_id = aa.attribute_id
           and tam.attribute_id = ida.attribute_id
           and ida.widget_name = idw.widget_name
           and ida.attribute_id = $id
	   and tam.object_type_id = $list_id
    "

    set r [::im::dynfield::Element create ::${id}__$list_id]
    $r db_1row dbq..get_element $sql
    if {[lsearch [im_dynfield_multimap_ids] [$r storage_type_id]] <0} {
	$r set multiple_p 0
    } else {
	$r set multiple_p 1
    }
    $r destroy_on_cleanup
    return $r
}

::im::dynfield::Element ad_instproc save {} {
    This will save an existing Dynfield Element.
} {
    my instvar attribute_id dynfield_attribute_id required_p section_heading pretty_name pretty_plural default_value 
    my instvar max_n_values include_in_search_p also_hard_coded_p deprecated_p label_style sort_order widget
    my instvar min_n_values help_text list_id default_value
    
    db_dml up_acs_attributes "update acs_attributes set pretty_name = :pretty_name, pretty_plural=:pretty_plural default_value = :default_value, min_n_values = :min_n_values, max_n_values = :max_n_values where attribute_id = :attribute_id"
    
    db_dml up_im_dynfield_att "update im_dynfield_attributes set include_in_search_p = :include_in_search_p, also_hard_coded_p = :also_hard_coded_p, deprecated_p = :deprecated_p, widget_name = :widget where attribute_id = :dynfield_attribute_id"
    
    db_dml up_idl "update im_dynfield_layout set label_style = :label_style, pos_y = :sort_order where attribute_id = :dynfield_attribute_id"
    
    db_dml up_tam "update im_dynfield_type_attribute_map set required_p = :required_p, section_heading = :section_heading, help_text = :help_text, default_value = :default_value where attribute_id = :dynfield_attribute_id and object_type_id = :list_id"
}

::im::dynfield::Element instproc initialize_loaded_object {} {
    # Dummy placeholder so we don't run into issues with caching
}

::im::dynfield::Element ad_instproc append_to_form {
    -form_name
} {
    Append the Element as a form widget to the form
    
    @param form_name Name of the form to which we shall append
} {
    my instvar datatype widget_name attribute_name required_p pretty_name help_text section_heading default_value
    
    
    
    set widget [::im::dynfield::Widget get_instance_from_db -id [::im::dynfield::Widget widget_id -widget_name $widget_name]]
    
    if {$section_heading ne ""} {
        template::form::section -legendtext $section_heading $form_name $section_heading
    }
    
    if {![template::element::exists $form_name "$attribute_name"]} {
	    template::element create $form_name "$attribute_name" \
	        -datatype "$datatype" [ad_decode $required_p "f" "-optional" ""] \
	        -widget [$widget set widget] \
	        -label "$pretty_name" \
	        -options [$widget set option_list] \
	        -custom [$widget set custom_parameters] \
	        -html [$widget set html_parameters] \
	        -help_text $help_text \
	        -value "$default_value"
    }
}

::im::dynfield::Element ad_instproc form_element {
    {-form_element_name ""}
} {
    Return the Element as a form block element
} {
    my instvar datatype widget_name attribute_name required_p pretty_name help_text section_heading attribute_id default_value object_type
    
    set widget [::im::dynfield::Widget get_instance_from_db -id [::im::dynfield::Widget widget_id -widget_name $widget_name]]
    
    set form_elements [list]
    if {$section_heading ne ""} {
        lappend form_elements [list -section "sec_$attribute_id" [list legendtext "$section_heading"] [list legend [list class myClass id myId]]]
    }
    
    # Deal with a different name of the attribute in this form
    if {$form_element_name == ""} {
        set form_element_name "${object_type}__$attribute_name"
    }
    
    # Check if this is a multiple element
    if {[lsearch [im_dynfield_multimap_ids] [$widget storage_type_id]] <0} {
        set multiple_string ""
        set value_string "value"
    } else {
        set multiple_string ",multiple"
        set value_string "values"
    }
    lappend form_elements [list \
        $form_element_name:${datatype}([$widget set widget])[ad_decode $required_p "f" ",optional" ""]$multiple_string \
        [list label "$pretty_name"] \
        [list options "[$widget set option_list]"] \
	    [list custom [$widget set custom_parameters]] \
	    [list html [$widget set html_parameters]] \
	    [list help_text $help_text] \
	    [list $value_string "$default_value"]]
	 
	return $form_elements
}


#############################
# 
# Dynfield Widgets
#
#############################

::xotcl::Class create ::im::dynfield::Widget \
    -slots {
        xo::Attribute create widget_name
        xo::Attribute create widget_id -default ""
        xo::Attribute create pretty_name
        xo::Attribute create pretty_plural -default ""
        xo::Attribute create storage_type_id -default "10007"
        xo::Attribute create acs_datatype -default "string"
        xo::Attribute create widget
        xo::Attribute create sql_datatype -default "text"
        xo::Attribute create parameters -default ""
        xo::Attribute create custom_parameters -default ""
        xo::Attribute create html_parameters -default ""
        xo::Attribute create option_list -default ""
        xo::Attribute create deref_plpgsql_function -default "im_name_from_id"
    } -ad_doc {
        Class to handle the dynfield widgets.
    }
    
::im::dynfield::Widget ad_proc widget_id {-widget_name} {
    Get the widget id for a widget, cached
} {
    return [util_memoize [list db_string widget "select widget_id from im_dynfield_widgets where widget_name = '$widget_name'"]]    
}

::im::dynfield::Widget ad_proc widget_url {
    {-widget_name ""}
    {-widget_id ""}
} {
    Return the URL for a widget
} {
    if {$widget_id == ""} {
        set widget_id [::im::dynfield::Widget widget_id -widget_name $widget_name]
    }
    return [export_vars -base "/intranet-dynfield/widget-new" -url {widget_id}]
}

::im::dynfield::Widget ad_proc get_widget {-widget_name} {
    Get the widget with the widget_name. Uses a cached widget_id
} {
    set widget_id [::im::dynfield::Widget widget_id -widget_name $widget_name]
    return [::im::dynfield::Widget get_instance_from_db -id $widget_id]
}


::im::dynfield::Widget ad_proc get_instance_from_db {-id} {
    Initialize a new Widget object.
    @param widget_name Name of the widget, much more convenient then the widget_id 
} {
    set r [::im::dynfield::Widget create ::$id]
    $r db_1row dbq..get_widget "select * from im_dynfield_widgets where widget_id = '$id'"

    set parameter_list [lindex [$r set parameters] 0]

    # Find out if there is a "custom" parameter and extract its value
    # "Custom" is the parameter to pass-on widget parameters from the
    # DynField Maintenance page to certain form Widgets.
    # Example: "custom {sql {select ...}}" in the "generic_sql" widget.
    set custom_pos [lsearch $parameter_list "custom"]
    if {$custom_pos >= 0} {
 	    $r set custom_parameters [lindex $parameter_list [expr $custom_pos + 1]]
    } else {
        $r set custom_parameters ""
    }

    set html_pos [lsearch $parameter_list "html"]
    if {$html_pos >= 0} {
 	    $r set html_parameters [lindex $parameter_list [expr $html_pos + 1]]
    } else {
        $r set html_parameters ""
    }

    set options_pos [lsearch $parameter_list "options"]
    if {$options_pos >= 0} {
	    $r set option_list [lindex $parameter_list [expr $options_pos + 1]]
    } else {
        $r set option_list ""
    }
    
    $r destroy_on_cleanup
    return $r
}

::im::dynfield::Widget ad_instproc save_new {} {
    Create a new widget. This translates the options_list, custom parameters and the like
    correctly.
    
    If the widget is of im_category_tree then the options, if set, will be added to im_categories 
} {
    
    my instvar parameters html_parameters custom_parameters widget option_list widget_name pretty_name pretty_plural \
        sql_datatype storage_type_id acs_datatype deref_plpgsql_function
    
    if {$pretty_plural == ""} {
        set pretty_plural $pretty_name
    }    
    
    if {$parameters == ""} {
        set parameters [list]
    }
    # deal with the parameters
    if {$html_parameters ne ""} {
        lappend parameters [list html $html_parameters]
    }
    
    if {$custom_parameters ne ""} {
        lappend parameters [list custom $custom_parameters]
    }
    
    switch $widget {
        im_category_tree {
            # This is a category widget. Make sure to enter the categories
            if {[lindex $custom_parameters 0] == "category_type"} {
                set category_type [lindex $custom_parameters 1]
            }
            foreach option $option_list {
                # This should fail if we want to enter an already existing category.
                ::xo::db::sql::im_category new -category_id [db_nextval im_categories_seq] \
                    -category $option -category_type $category_type -description ""         
            }
            
            set acs_datatype "integer"
            set sql_datatype "integer"
        }
        default {
            if {$option_list ne ""} {
                lappend parameters [list options $option_list]
            }
        }
    }
    
    
    xo::db::sql::im_dynfield_widget new \
        -widget_id "" \
        -creation_date "" \
        -creation_user "" \
        -creation_ip "" \
        -context_id "" \
        -object_type "im_dynfield_widget" \
        -widget_name $widget_name \
        -pretty_name $pretty_name \
        -pretty_plural $pretty_plural \
    	-storage_type_id $storage_type_id \
    	-acs_datatype $acs_datatype \
    	-widget $widget \
    	-sql_datatype $sql_datatype \
    	-deref_function $deref_plpgsql_function \
    	-parameters $parameters

}

::im::dynfield::Widget ad_proc widgets {} {
    Returns a list of widget_names which we can use
} {
    return [db_list dbq..get_widgets "select widget_name from im_dynfield_widgets"]
}


::im::dynfield::Widget ad_instproc operand_options {
} {
    Return the operand options for this Widget to be used in search
    
    This should be extended later to take into account more of the AMS widgets, but for now we are
    just using the default dynfield widgets. Adopt it for more widgets!
} {
    set widget [my widget]
    
    # Deal with number widgets
    if {$widget == "text"} {
        switch [my acs_datatype] {
            integer - number - float {
                set widget "number"
            }
        }
    }
    
    set null_display "- - - - - -"
    switch $widget {
	    checkbox - multiselect - category_tree - im_category_tree - radio - select - generic_sql - im_cost_center_tree {
            return "[list \
				    [list "$null_display" ""] \
                    [list "[_ intranet-contacts.is_-]" "selected"] \
                    [list "[_ intranet-contacts.is_not_-]" "not_selected"] \
                ]"
	    }
	    date {
	        return "[list \
			 [list "$null_display" ""] \
                                     [list "[_ intranet-contacts.is_less_than_-]" "less_than"] \
                                     [list "[_ intranet-contacts.is_more_than_-]" "more_than"] \
                                     [list "[_ intranet-contacts.is_recurrence_within_next_-]" "recurrence_within_next"] \
                                     [list "[_ intranet-contacts.is_recurrence_within_last_-]" "recurrence_within_last"] \
                                     [list "[_ intranet-contacts.is_after_-]" "after"] \
                                     [list "[_ intranet-contacts.is_before_-]" "before"] \
                                    ]"
	    }
	    number {
	        return "[list \
                [list "[_ intranet-contacts.is_-]" "is"] \
                [list "[_ intranet-contacts.is_greater_than_-]" "greater_than"] \
                [list "[_ intranet-contacts.is_less_than_-]" "less_than"] \
            ]"
	    }
        default {
            return "[list \
			 [list "$null_display" ""] \
                                     [list "[_ intranet-contacts.contains_-]" "contains"] \
                                     [list "[_ intranet-contacts.does_not_contain_-]" "not_contains"] \
                                    ]"
        }
    }
}

::im::dynfield::Widget ad_instproc template_form_widget {} {
    returns element(s) string(s) suitable for inclusion in templates
} {
}

::im::dynfield::Widget ad_instproc value_method {} {
    the name of a database procedure to be called when returning a value to this procedure. The procedure will only get the value_id supplied in the form_save_value request and must convert that to whatever format it wants. In the simplest case it would return the value_id itself and then when you use form_set_value, value_text, value_html, csv_value actions a trip would need to be made to the database to return the appropriate values. If at all possible this procedure should return all the information necessary to format the value with this procedure (and thus not require another trip to the database which would siginifcantly decrease performance).
} {
}

##############################
# Object Cache
# 
# Kudos to Stefan Soberning
##############################

::xotcl::Class create ::im::dynfield::ElementCache
 ::im::dynfield::ElementCache instproc get_instance_from_db {
    -id:required
    {-list_id ""}
 } {
     if {$list_id == ""} {
         # Apparently the list is not important, might be the case if the help_text is not needed or the default value
         set list_id [ams::list::get_id -attribute_id $id]
     }
     set object ::${id}__$list_id
     set code [ns_cache eval xotcl_object_cache $object {
          set created 1
          set o [next]
          return [::Serializer deepSerialize $o]
        }]
    if {![info exists created]} {
      if {[my isobject $object]} {
      } else {
            set o [eval $code]
            $object initialize_loaded_object
      }
    }
    
    return $object
}

::im::dynfield::ElementCache instproc delete {-id:required -list_id:required} {
      next
      my flush -id $id -list_id $list_id
}

::im::dynfield::ElementCache ad_proc flush {-id:required -list_id:required} {
    Flush
} {
    ::xo::clusterwide ns_cache flush xotcl_object_cache ::${id}__$list_id
    ds_comment "Flushing ::$id"
}

::im::dynfield::ElementCache instproc flush {-id:required -list_id:required} {
      ::xo::clusterwide ns_cache flush xotcl_object_cache ::${id}__$list_id
      ds_comment "Flushing ::$id"
}

::im::dynfield::Element mixin ::im::dynfield::ElementCache
