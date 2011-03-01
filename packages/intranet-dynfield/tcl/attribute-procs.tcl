# /packages/intranet-dynfield/tcl/attribute-procs.tcl

ad_library {

    Procs to help with attributes for object types

    @author mbryzek@arsdigita.com
    @author frank.bergmann@project-open.com
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
        if {[lindex $multimap 1] == $table_name} {
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
        if {[lindex $multimap 0] == $storage_type_id} {
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
    Create a completely new im_dynfield attribute and handle all strange 
    side conditions.

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

    # massage parameters
    set attribute_name [string tolower $attribute_name]
    if {$pretty_plural == ""} { set pretty_plural $pretty_name }

    # Get the storage type from the widget.
    db_1row select_widget_pretty_and_storage_type { 
	    select	storage_type_id,
	            im_category_from_id(storage_type_id) as storage_type,
	            sql_datatype
	      from	im_dynfield_widgets 
	     where	widget_name = :widget_name 
    }
    
    if {$storage_type_id == [im_dynfield_storage_type_id_multimap]} {
        set multimap_p 1
    } else {
        set multimap_p 0
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

    # --------------------------------------------------------------------
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

    # Create the new DynField attribute.
    # The PL/SQL function takes care of setting base permissions
    # and setting up the im_dynfield_type_attribute_map.

    set attribute_id [db_string attrib_new "
	select im_dynfield_attribute_new (
		:object_type,
		:attribute_name,
		:pretty_name,
		:widget_name,
		:datatype,
		:required_p,
		:pos_y,
		:also_hard_coded_p,
                :table_name
	)
    "]


    # update im_dynfield_attributes table
    db_dml "update im_dynfield_attributes" "
		update im_dynfield_attributes set
			widget_name = :widget_name,
			include_in_search_p = :include_in_search_p
		where attribute_id = :attribute_id
	"

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

    # Add the column to the table if it doesn't already exist
    # and if the attribut's storage type if "value" (not a multimap)
    if {[string equal $modify_sql_p "t"] && ![db_column_exists $table_name $attribute_name] && !$multimap_p } {
        db_dml add_column "alter table $table_name add column $attribute_name $sql_datatype"
    }
   return $attribute_id

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



namespace eval attribute { 

    ad_proc -public name {
        attribute_id
    } {
        this code returns the name of an attribute
    } {
        return [db_string get_attribute_name {} -default ""]
    }

    ad_proc -public delete_xt { im_dynfield_attribute_id } {
        Intranet-Dynfield extended version of deleting the specified attribute id 
        and all its values. This is irreversible. 
        Returns 1 if the attribute was actually deleted. 0 otherwise.
        <li>1. Drop the column
        <li>2. Drop the attribute
        <li>3. Return

        @author Frank Bergmann (frank.bergmann@project-open.com)
        @author Michael Bryzek (mbryzek@arsdigita.com)
        @creation-date 2005-01-25
    } {

        if { ![db_0or1row select_attr_info {
    	select
    		aa.attribute_name as acs_attribute_name,
    		aa.attribute_id as acs_attribute_id,
    		t.object_type,
    		aa.storage,
    		aa.table_name,
    		aa.column_name
    	from
    		acs_attributes aa,
    		im_dynfield_attributes fa,
    		acs_object_types t
    	where
    		fa.acs_attribute_id = aa.attribute_id
    		and t.object_type = aa.object_type
    		and fa.attribute_id = :im_dynfield_attribute_id
        }] } {
            # Attribute doesn't exist
    	ad_return_complaint 1 "Error in attribute::delete_xt: 
    	attribute #$attribute_id doesn't exist"
    	return 0
        }

        if {"" == $column_name} {
    	set column_name $acs_attribute_name
        }

        if { [empty_string_p $table_name] || [empty_string_p $column_name] } {
            # We have to have both a non-empty table name and column name
            error "We do not have enough information to automatically remove this\
     attribute. Namely, we are missing either the table name or the column name"
        }

        set plsql [list]
        lappend plsql [list "drop_attribute" "FOO" "db_exec_plsql"]
        if { [im_column_exists $table_name $column_name] } {
            #lappend plsql [list "drop_attr_column" "FOO" "db_dml"]
        }

        foreach pair $plsql {
            eval [lindex $pair 2] [lindex $pair 0] [lindex $pair 1]
        }

        return 1
    }


}
