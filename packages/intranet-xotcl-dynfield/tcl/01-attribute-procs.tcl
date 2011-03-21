# packages/intranet-xo-dynfield/tcl/01-attribute-procs.tcl
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

  Support procs for attribute handling in the intranet-dynfield package

  @vss $Workfile: intranet-dynfield-procs.tcl $ $Revision: 1.11 $ $Date: 2010/04/25 16:41:39 $

}


############################
#
# Handling of attributes
#
############################


::xotcl::Class create ::im::dynfield::Attribute \
    -superclass ::xo::db::Attribute \
    -parameter {
	{widget_name}
	{already_existed_p f}
	{deprecated_p f}
	{include_in_search_p t}
	{also_hard_coded_p t}
	{storage_type_id}
	{widget}
	{widget_parameters}
	{sql_datatype}
	{deref_plpgsql_function "im_name_from_id"}
	{table_name}
	{pos_y 0}
	{label_style "plain"}
	{default_value ""}
	{dynfield_attribute_id ""}
    }    


::im::dynfield::Attribute instproc create_attribute {} {
    if {![my create_acs_attribute]} return
    
    my instvar datatype pretty_name min_n_values max_n_values domain column_name table_name required name
    my instvar widget_name already_existed_p deprecated_p include_in_search_p also_hard_coded_p default_value
    my instvar storage_type_id widget widget_parameters sql_datatype deref_plpgsql_function pos_y label_style
    
    set object_type [$domain object_type]
    
    # Create the class if it does not exist (albeit unlikely)
    if {![::xo::db::Class object_type_exists_in_db -object_type $object_type]} {
        $domain create_object_type
    }
    
    if {$required == "false"} {
        set required_p 0
    } else {
        set required_p 1
    }

    if {$required == "false"} {
        set required_p 0
    } else {
        set required_p 1
    }
    
    # Create the acs_attribute along with the im_dynfield one.
    # If the acs_attribute already exists we just create the dynfield attribute
    
    set im_dynfield_attribute_exists [im_dynfield::attribute::exists_p -object_type $object_type -attribute_name $name]
    
    if {![exists_and_not_null table_name]} {
        set table_name [::xo::db::Class get_table_name -object_type $object_type]
    }
    
    if {!$im_dynfield_attribute_exists} {
	ns_log Notice "WE HAVE TO CALL attribute::add ??????"
	im_dynfield::attribute::add \
	    -object_type $object_type \
	    -widget_name $widget_name \
	    -attribute_name $name \
	    -pretty_name $pretty_name \
	    -pretty_plural $pretty_name \
	    -table_name $table_name \
	    -required_p $required_p \
	    -modify_sql_p "t" \
	    -deprecated_p $deprecated_p \
	    -datatype $datatype \
	    -default_value $default_value \
	    -include_in_search_p $include_in_search_p \
	    -also_hard_coded_p $also_hard_coded_p \
	    -label_style $label_style \
	    -pos_y $pos_y
    }
}

::im::dynfield::Attribute ad_instproc attribute_reference {tn} {
    Returns the column reference for retrieving the attribute value
    
    If there exists a deref function the value is derefed
} {
    my instvar column_name name table_name deref_plpgsql_function multivalued
    
    if {![info exists table_name]} {
	set table_name $tn
    }
    if {$tn ne $table_name} {
	ns_log Debug "Trying to access attribute $name with wrong table $tn instead of $table_name"
    }
    
    
    if {$column_name ne $name} {
	set att_ref "$table_name.$column_name"
    } else {
	set att_ref "$table_name.$name"
    }
    
    
    if {$deref_plpgsql_function ne "" && $multivalued == false} {
	set att_ref "${deref_plpgsql_function}(${att_ref}) as ${name}_deref, ${att_ref}"
    } elseif {$deref_plpgsql_function eq ""} {
	set att_ref "${att_ref} as ${name}_deref, ${att_ref}"
    }
    return "$att_ref as $name"
}

if {0} {
::im::dynfield::Attribute ad_proc dynfield_attributes {
    {-object_type_ids:required}
    {-privilege ""}
    {-user_id ""}
} {
    Returns a list of dynfield_attributes with object_type_id of the attributes to display. This means we return a list of (attribute_id object_type_id) pairs.
    
    The list is sorted in order of how the attributes should appear according to the object_type_id order
    
    @param object_type_ids This is a list of object_type_ids. Note that the order is important
    @param user_id User ID for whom to check the privilege
    @param privilege Check that the user has this privilege. Empty string does mean no permission check
} {
    set dynfield_attribute_ids [list]
    set attribute_ids [list]
    db_foreach attributes "
	select dl.attribute_id, object_type_id as object_type_id
	from im_dynfield_type_attribute_map tam, im_dynfield_layout dl
	where tam.attribute_id = dl.attribute_id
	and object_type_id in ([template::util::tcl_to_sql_list $object_type_ids])
	order by pos_y
    " {
	if {[lsearch $attribute_ids $attribute_id] < 0} {
	    lappend attribute_ids $attribute_id
	    if {$privilege == ""} {
		lappend dynfield_attribute_ids [list $attribute_id $object_type_id]
	    } else {
		if {[im_object_permission -object_id $attribute_id -user_id $user_id -privilege $privilege]} {
		    lappend dynfield_attribute_ids [list $attribute_id $object_type_id]
		}
	    }
	}
    }
    return $dynfield_attribute_ids
}


::im::dynfield::Attribute ad_instproc save {} {
    This will save a dynfield attribute in the respective tables
} {
    
    my instvar attribute_id dynfield_attribute_id required_p section_heading pretty_name pretty_plural default_value 
    my instvar max_n_values include_in_search_p also_hard_coded_p deprecated_p label_style sort_order widget
    my instvar min_n_values
    
    db_dml up_acs_attributes "update acs_attributes set pretty_name = :pretty_name, pretty_plural=:pretty_plural default_value = :default_value, min_n_values = :min_n_values, max_n_values = :max_n_values where attribute_id = :attribute_id"
    
    db_dml up_im_dynfield_att "update im_dynfield_attributes set include_in_search_p = :include_in_search_p, also_hard_coded_p = :also_hard_coded_p, deprecated_p = :deprecated_p, widget_name = :widget where attribute_id = :dynfield_attribute_id"
    
    db_dml up_idl "update im_dynfield_layout set label_style = :label_style, pos_y = :sort_order where attribute_id = :dynfield_attribute_id"
}



##########################################
# 
# Integration between list and attribute
#
##########################################

ad_proc im_dynfield::attribute::map {
    {-object_type_id ""}
    {-object_type_ids ""}
    -attribute_id:required
    {-sort_order ""}
    {-required_p ""}
    {-section_heading ""}
} {
    Map an ams option for an attribute to an option_map_id, if no value is supplied for 
    option_map_id a new option_map_id will be created.
    @param sort_order if null then the attribute will be placed as the last attribute in this groups sort order
    @param attribute_id Dynfield attribute_id
    @return option_map_id
} {
    
    foreach object_type_id [concat $object_type_id $object_type_ids] {

	    db_dml delmap "
		    delete from im_dynfield_type_attribute_map
		    where attribute_id = :attribute_id and object_type_id = :object_type_id
	    "
        
        if {$required_p == ""} {
            # Determine if an attribute should be required in this list by the default value for required.
            set required_p [db_string required "select case when aa.min_n_values = 0 then 'f' else 't' end as required_p from acs_attributes aa, im_dynfield_attributes ida where ida.acs_attribute_id = aa.attribute_id and ida.attribute_id = :attribute_id" -default "f"]
        }
	    
	    db_dml insmap "
		insert into im_dynfield_type_attribute_map (
			attribute_id,
			object_type_id,
			display_mode,
			required_p,
			section_heading
		) values (
			:attribute_id,
			:object_type_id,
			'edit',
			:required_p,
			:section_heading
		)
	"
	    db_dml delsort "
	        delete from im_dynfield_layout where attribute_id = :attribute_id and label_style = 'plain'
	    "

        db_dml inssort "
            insert into im_dynfield_layout (attribute_id,label_style,pos_y) values (:attribute_id,'plain',:sort_order)
        "
    }
}

ad_proc im_dynfield::attribute::unmap {
    -object_type_id:required
    -attribute_id:required
} {
    Unmap an ams option from an ams list
} {
 
    db_dml delmap "
	    delete from im_dynfield_type_attribute_map
	    where attribute_id = :attribute_id and object_type_id = :object_type_id
    "
    
    db_dml delsort "
        delete from im_dynfield_layout where attribute_id = :attribute_id and label_style = 'plain'
    "
    
}

ad_proc im_dynfield::attribute::required {
    -object_type_id:required
    -attribute_id:required
} {
    Specify and ams_attribute as required in an ams list
} {
    db_dml ams_list_attribute_required {
        update im_dynfield_type_attribute_map
        set required_p = 't'
        where object_type_id = :object_type_id
        and attribute_id = :attribute_id
    }
}

ad_proc im_dynfield::attribute::optional {
    -object_type_id:required
    -attribute_id:required
} {
    Specify and ams_attribute as optional in an ams list
} {
    db_dml ams_list_attribute_optional {
        update im_dynfield_type_attribute_map
        set required_p = 'f'
        where object_type_id = :object_type_id
        and attribute_id = :attribute_id
    }
}

}

