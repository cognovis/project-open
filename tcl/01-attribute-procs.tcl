# packages/intranet-dynfield/tcl/intranet-dynfield-procs.tcl
ad_library {

  Support procs for attribute handling in the intranet-dynfield package

  @vss $Workfile: intranet-dynfield-procs.tcl $ $Revision$ $Date$

}


namespace eval im_dynfield::attribute {}
namespace eval im::dynfield:: {}

ad_proc -public im_dynfield_storage_type_id_value { } { return 10007 }
ad_proc -public im_dynfield_storage_type_id_multimap { } { return 10005 }

ad_proc -public im_dynfield_multimaps {} {
    Return a list of list of the multimap storage types and their table
    which at the moment is 10005 for normal multimapping
    and 10006 for im_category multimapping
} {
    return [list [list 10005 "im_dynfield_attr_multi_value"] [list 10006 "im_dynfield_cat_multi_value"]]
}

ad_proc -public im_dynfield_multimap_ids {} {
    Return the multimap ids
} {
    set ids [list]
    foreach multimap [im_dynfield_multimaps] {
        lappend ids [lindex $multimap 0]
    }
    return $ids
}

ad_proc -public im_dynfield_multimap_tables {} {
    Return the multimap tables
} {
    set tables [list]
    foreach multimap [im_dynfield_multimaps] {
        lappend tables [lindex $multimap 1]
    }
    return $tables
}

ad_proc -public im_dynfield_multimap_id {
    -table_name
} {
    Return the storage type id of a table
} {
    foreach multimap [im_dynfield_multimaps] {
        if {[lindex $multimap 1] eq $table_name} {
            return [lindex $multimap 0]
            break
        }
    }
}

ad_proc -public im_dynfield_multimap_table {
    -storage_type_id
} {
    Return the table_name of a storage_type_id
} {
    foreach multimap [im_dynfield_multimaps] {
        if {[lindex $multimap 0] eq $storage_type_id} {
            return [lindex $multimap 1]
            break
        }
    }
}

ad_proc -public im_dynfield::attribute::get_name_from_id {
    -attribute_id
} {
    Returns the cached name for the dynfield attribute
    
    @param attribute_id Dynfield attribute_id. This differs from the attribute_id of acs_attributes as the dynfield attribute is actually an acs_object so we can have permissions on it.
} {
    return [util_memoize [list db_string name "select attribute_name from acs_attributes aa, im_dynfield_attributes ida where ida.acs_attribute_id = aa.attribute_id and ida.attribute_id = $attribute_id" -default ""]]
}

ad_proc -public im_dynfield::attribute::add {
    -object_type:required
    -widget_name:required
    {-attribute_id 0}
    -attribute_name:required
    -pretty_name:required
    {-pretty_plural ""}
    -table_name:required
    {-required_p "f"}
    {-modify_sql_p "f"}
    {-include_in_search_p "f"}
    {-also_hard_coded_p "f"}
    {-deprecated_p "f"}
    {-datatype ""}
    {-default_value ""}
    {-label_style "plain"}
    {-pos_y "0"}
    {-help_text ""} 
    {-section_heading ""}
    {-default_value ""}
} {
    Procedure to add all the necessary dynfields after add_xt has been called

    @param object_type Object Type of the attribute
    @param widget_name Widget Name (see im_dynfield_widgets table)
    @param attribute_id Attribute_id for existing attributes
    @param attribute_name Name of the attribute, also used as column name
    @param pretty_name Pretty Name for display
    @param pretty_plural Pretty Plural (for display)
    @param table_name Table Name where the attribute will be stored. This must already exist
    @param required_p Is the field required
    @param modify_sql_p Should the column be created in the table if it does not already exist
    @param deprecated_p Is this field considered deprecated
    @param datatype What is the datatype, defaults to the type of the widget
    @param default_value What is the default value
    @param also_hard_coded_p Does this field also exist hard coded in the PO-screens? Set this field if it should not appear in PO screens
    @param pos_y Give a value for the Y-position, ranging from '0' (top) to '100' (bottom). Currently, DynFields are appended at the end of any form in the order given by this variable. 
    @param help_text Help Text for this attribute in the widget
    @param section_heading Section Heading for  the attribute in the default_list
    @param default_value Default value which will be used for the attribute
} {
    acs_object_type::get -object_type $object_type -array "object_info"
    
    if {$pretty_plural eq ""} {
        set pretty_plural $pretty_name
    }
    
    db_1row select_widget_pretty_and_storage_type { 
	select	storage_type_id,
	        im_category_from_id(storage_type_id) as storage_type
	from	im_dynfield_widgets 
	where	widget_name = :widget_name 
    }


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


    # Make sure there is an entry in acs_object_type_tables for the
    # object type's main table. This table is needed by a RI constraint
    # acs_attributes.

    set ext_table_id_column $object_info(id_column)
    foreach ext_table_name [list $object_info(table_name) $table_name] {
	set extension_table_exists_p [db_string ext_table_exists "select count(*) from acs_object_type_tables where object_type = :object_type and table_name = :ext_table_name"]
    
	if {!$extension_table_exists_p} {
	    
	    db_dml insert_table {
	      insert into acs_object_type_tables (
	        object_type,
	        table_name,
	        id_column
	      ) values (
	        :object_type,
	        :ext_table_name,
	        :ext_table_id_column
	      )
	    }
	}
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
	    
	}
    }

    im_dynfield::attribute::make_visible -attribute_id $attribute_id -object_type $object_type

    # update im_dynfield_attributes table
    db_dml "update im_dynfield_attributes" "
		update im_dynfield_attributes set
			widget_name = :widget_name,
			include_in_search_p = :include_in_search_p,
			also_hard_coded_p = :also_hard_coded_p
		where attribute_id = :attribute_id
	"

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
			pos_y = :pos_y,
			label_style = :label_style
		where
			attribute_id = :attribute_id
			and page_url = 'default'
    "

    db_dml update_texts "
        update im_dynfield_type_attribute_map set
            help_text = :help_text,
            section_heading = :section_heading,
            default_value = :default_value
        where attribute_id = :attribute_id
    "
    return $attribute_id
    
    # end of namespace attribute
}

ad_proc -public im_dynfield::attribute::make_visible {
    -attribute_id
    -object_type
} {
    Makes an attribute visible in DynFields
    
    @param attribute_id Attribute ID of the attribute we want to make visible
    @param object_type Object Type of the attribute
} {
    
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
	ns_log Notice "TAM:: $type_category :: $object_type_id"
	set exists_p [db_string exists "
	select count(*) from im_dynfield_type_attribute_map 
	where attribute_id = :attribute_id and object_type_id = :object_type_id"]
	
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
}

ad_proc -public im_dynfield::attribute::exists_p {
    -object_type:required
    -attribute_name:required
} {
    Check if the intranet-dynfield attribute already exists.<br>
    Considers the case that intranet-dynfield got installed and deinstalled
    before, so it only considers attributes that exist in both
    acs_attributes and im_dynfield_attributes.

    @return 1 if the attribute_name exists for this object_type and 
            0 if the attribute_name does not exist
} {
    return [util_memoize [list im_dynfield::attribute::exists_p_not_cached -object_type $object_type -attribute_name $attribute_name]]
}

ad_proc -private im_dynfield::attribute::exists_p_not_cached {
    -object_type:required
    -attribute_name:required
} {
    Check if the intranet-dynfield attribute already exists.<br>
    Considers the case that intranet-dynfield got installed and deinstalled
    before, so it only considers attributes that exist in both
    acs_attributes and im_dynfield_attributes.

    @return 1 if the attribute_name exists for this object_type and 
            0 if the attribute_name does not exist
} {
    set attribute_exists_p [db_string attribute_exists "
        select count(*) 
        from
                acs_attributes a,
                im_dynfield_attributes fa
        where
                a.attribute_id = fa.acs_attribute_id
                and a.object_type = :object_type
                and a.attribute_name = :attribute_name
    " -default 0]
    return $attribute_exists_p

}

ad_proc -private im_dynfield::attribute::get {
    -object_type:required
    -attribute_name:required
} {
    Returns the im_dynfield_attribute_id, or 0 if there is none.
} {
    set attribute_id [db_string attribute_id "
        select	fa.attribute_id
        from
                acs_attributes a,
                im_dynfield_attributes fa
        where
                a.attribute_id = fa.acs_attribute_id
                and a.object_type = :object_type
                and a.attribute_name = :attribute_name
    " -default 0]
    return $attribute_id

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
        {already_existed_p false}
        {deprecated_p false}
        {include_in_search_p true}
        {also_hard_coded_p true}
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

    if {$required eq "false"} {
        set required_p 0
    } else {
        set required_p 1
    }
    
    # Create the acs_attribute along with the im_dynfield one.
    # If the acs_attribute already exists we just create the dynfield attribute

    set im_dynfield_attribute_exists [im_dynfield::attribute::exists_p -object_type $object_type -attribute_name $name]
    
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
    
    if {$deref_plpgsql_function ne "" && $multivalued eq false} {
        set att_ref "${deref_plpgsql_function}(${att_ref}) as ${name}_deref, ${att_ref}"
    }
    return "$att_ref as $name"
}

::im::dynfield::Attribute ad_proc dynfield_attributes {
    {-list_ids:required}
    {-privilege ""}
    {-user_id ""}
} {
    Returns a list of dynfield_attributes with list_id of the attributes to display. This means we return a list of (attribute_id list_id) pairs.
    
    The list is sorted in order of how the attributes should appear according to the list_id order
    
    @param list_ids This is a list of list_ids. Note that the order is important
    @param user_id User ID for whom to check the privilege
    @param privilege Check that the user has this privilege. Empty string does mean no permission check
} {
    set dynfield_attribute_ids [list]
    set attribute_ids [list]
    foreach list_id $list_ids {
        db_foreach attributes {
            select dl.attribute_id
            from im_dynfield_type_attribute_map tam, im_dynfield_layout dl
            where tam.attribute_id = dl.attribute_id
            and object_type_id = :list_id
            order by pos_y
        } {
            if {[lsearch $attribute_ids $attribute_id] < 0} {
                lappend attribute_ids $attribute_id
                if {$privilege eq ""} {
                    lappend dynfield_attribute_ids [list $attribute_id $list_id]
                } else {
                    if {[im_object_permission -object_id $attribute_id -user_id $user_id -privilege $privilege]} {
                        lappend dynfield_attribute_ids [list $attribute_id $list_id]
                    }
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
    {-list_id ""}
    {-list_ids ""}
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
    
    foreach list_id [concat $list_id $list_ids] {

	    db_dml delmap "
		    delete from im_dynfield_type_attribute_map
		    where attribute_id = :attribute_id and object_type_id = :list_id
	    "
        
        if {$required_p eq ""} {
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
			:list_id,
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
    -list_id:required
    -attribute_id:required
} {
    Unmap an ams option from an ams list
} {
 
    db_dml delmap "
	    delete from im_dynfield_type_attribute_map
	    where attribute_id = :attribute_id and object_type_id = :list_id
    "
    
    db_dml delsort "
        delete from im_dynfield_layout where attribute_id = :attribute_id and label_style = 'plain'
    "
    
}

ad_proc im_dynfield::attribute::required {
    -list_id:required
    -attribute_id:required
} {
    Specify and ams_attribute as required in an ams list
} {
    db_dml ams_list_attribute_required {
        update im_dynfield_type_attribute_map
        set required_p = 't'
        where object_type_id = :list_id
        and attribute_id = :attribute_id
    }
}

ad_proc im_dynfield::attribute::optional {
    -list_id:required
    -attribute_id:required
} {
    Specify and ams_attribute as optional in an ams list
} {
    db_dml ams_list_attribute_optional {
        update im_dynfield_type_attribute_map
        set required_p = 'f'
        where object_type_id = :list_id
        and attribute_id = :attribute_id
    }
}



