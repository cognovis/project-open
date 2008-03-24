ad_library {

    list procs for the ams package

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2005-02-14
    @cvs-id $Id$

}

namespace eval ams:: {}
namespace eval ams::list:: {}
namespace eval ams::list::attribute:: {}

ad_proc -public ams::list::url {
    -package_key:required
    -object_type:required
    -list_name:required
    {-pretty_name ""}
    {-description ""}
    {-return_url ""}
    {-return_url_label "Return to Where You Were"}
} {
} {
    return [export_vars -base "/intranet-dynfield/ams/list" -url {package_key object_type list_name pretty_name description return_url return_url_label}]
}

ad_proc -public ams::list::get {
    -list_id:required
    -array:required
} {
    Get the info on an ams_attribute
} {
    upvar 1 $array row
    db_1row select_list_info {} -column_array row
}

ad_proc -private ams::list::ams_attribute_ids_not_cached {
    -list_id:required
} {
    Get a list of ams_attributes.

    @return list of ams_attribute_ids, in the correct order

    @see ams::list::ams_attribute_ids
    @see ams::list::ams_attribute_ids_flush
} {
    return [db_list ams_attribute_ids {}]
}

ad_proc -private ams::list::ams_attribute_ids {
    -list_id:required
} {
    get this lists ams_attribute_ids. Cached.

    @return list of ams_attribute_ids, in the correct order

    @see ams::list::ams_attribute_ids_not_cached
    @see ams::list::ams_attribute_ids_flush
} {
    return [util_memoize [list ams::list::ams_attribute_ids_not_cached -list_id $list_id]]
}

ad_proc -private ams::list::ams_attribute_ids_flush {
    -list_id:required
} {
    Flush this lists ams_attribute_ids cache.

    @return list of ams_attribute_ids, in the correct order

    @see ams::list::ams_attribute_ids_not_cached
    @see ams::list::ams_attribute_ids
} {
    return [util_memoize_flush [list ams::list::ams_attribute_ids_not_cached -list_id $list_id]]
}

ad_proc -public ams::list::copy {
    -package_key:required
    -object_type:required
    -from_list_name:required
    -to_list_name:required
    {-to_pretty_name ""}
    {-to_description ""}
    {-to_description_mime_type "text/plain"}
    {-to_context_id ""}
} {
    Copy one ams_list to another
} {
    set to_pretty_name [string trim $to_pretty_name]
    set from_id [ams::list::get_list_id_not_cached -package_key $package_key -object_type $object_type -list_name $from_list_name]
    if { [exists_and_not_null from_id] } {
        set to_id [ams::list::get_list_id_not_cached -package_key $package_key -object_type $object_type -list_name $to_list_name]
        if { ![exists_and_not_null to_id] } {
            if { ![exists_and_not_null to_pretty_name] } {
                db_1row get_from_list_data {}
                set to_pretty_name "$pretty_name [_ intranet-dynfield.Copy]"
                set to_description $description
                set to_description_mime_type $description_mime_type
            }
            set to_id [ams::list::new \
                           -package_key $package_key \
                           -object_type $object_type \
                           -list_name $to_list_name \
                           -pretty_name $to_pretty_name \
                           -description $to_description \
                           -description_mime_type $to_description_mime_type \
                           -context_id $to_context_id]
        }
        if { $to_id != $from_id } {
            if { ![db_0or1row list_has_attributes_mapped {}] } {
                db_transaction {
                    db_dml copy_list {}
                }
                return 1
            }
        }
    }
    return 0

}



ad_proc -private ams::list::exists_p {
    -package_key:required
    -object_type:required
    -list_name:required
} {
    does an ams list like this exist?

    @return 1 if the list exists for this object_type and package_key and 0 if the does not exist
} {
    set list_id [ams::list::get_list_id -package_key $package_key -object_type $object_type -list_name $list_name]
    if { [exists_and_not_null list_id] } {
        return 1
    } else {
        return 0
    }
}

ad_proc -private ams::list::flush {
    -package_key:required
    -object_type:required
    -list_name:required
} {
    flush all inte info we have on an ams_list

    @return 1 if the list exists for this object_type and package_key and 0 if the does not exist
} {
    ams::list::ams_attribute_ids_flush -list_id [ams::list::get_list_id_not_cached -package_key $package_key -object_type $object_type -list_name $list_name]
    ams::list::get_list_id_flush -package_key $package_key -object_type $object_type -list_name $list_name
}

ad_proc -private ams::list::get_list_id {
    -package_key:required
    -object_type:required
    -list_name:required
} {
    return the list_id for the given parameters. Chached.
    @return list_id if none exists then it returns blank
} {
    return [ams::list::get_list_id_not_cached -package_key $package_key -object_type $object_type -list_name $list_name]

#    return [util_memoize [list ams::list::get_list_id_not_cached -package_key $package_key -object_type $object_type -list_name $list_name]]
}


ad_proc -private ams::list::get_list_id_not_cached {
    -package_key:required
    -object_type:required
    -list_name:required
} {
    return the list_id for the given parameters
    @return list_id if none exists then it returns blank
} {
    return [db_string get_list_id {} -default {}]
}

ad_proc -private ams::list::get_list_id_flush {
    -package_key:required
    -object_type:required
    -list_name:required
} {
    
    flush the memorized list_id for the given parameters.

    @return list_id if none exists then it returns blank
} {
    return [util_memoize_flush [list ams::list::get_list_id_not_cached -package_key $package_key -object_type $object_type -list_name $list_name]]
}

ad_proc -public ams::list::new {
    {-list_id ""}
    -package_key:required
    -object_type:required
    -list_name:required
    -pretty_name:required
    {-description ""}
    {-description_mime_type "text/plain"}
    {-context_id ""}
} {
    create a new ams_group

    @return group_id
} {

    # Check if the list id already exists
    if {[string eq "" $list_id]} {
	# we use the not cached proc so that if
        # it does not exists a blank value
        # is not saved for the list we are
        # creating here
	set existing_list_id_not_cached [ams::list::get_list_id -package_key $package_key -object_type $object_type -list_name $list_name]
    } 	
    
    if {[exists_and_not_null existing_list_id]} {
	return $existing_list_id
    } else {
	if { [empty_string_p $context_id] } {
	    set context_id [apm_package_id_from_key ams]
	}
	if { ![exists_and_not_null description] } {
	    set description_mime_type ""
	}
	
	set pretty_name [lang::util::convert_to_i18n -message_key "ams_list.${object_type}.${list_name}" -text "$pretty_name"]
	set extra_vars [ns_set create]
	oacs_util::vars_to_ns_set -ns_set $extra_vars -var_list { list_id package_key object_type list_name pretty_name description description_mime_type }
	set list_id [package_instantiate_object -extra_vars $extra_vars ams_list]
	
	return $list_id
    }
}



ad_proc -public ams::list::attribute::map {
    {-list_id ""}
    {-list_ids ""}
    -attribute_id:required
    {-sort_order ""}
    {-required_p "f"}
    {-section_heading ""}
} {
    Map an ams option for an attribute to an option_map_id, if no value is supplied for 
    option_map_id a new option_map_id will be created.
    @param sort_order if null then the attribute will be placed as the last attribute in this groups sort order
    @return option_map_id
} {
    foreach list_id [concat $list_id $list_ids] {

	db_dml delmap "
		delete from im_dynfield_type_attribute_map
		where attribute_id = :attribute_id and object_type_id = :list_id
	"

	db_dml insmap "
		insert into im_dynfield_type_attribute_map (
			attribute_id,
			object_type_id,
			display_mode
		) values (
			:attribute_id,
			:list_id,
			'edit'
		)

	"

#	if { ![exists_and_not_null sort_order] } {
#	    set sort_order [expr 1 + [db_string get_highest_sort_order {} -default "0"]]
#	}
#	# We need to update, therefore we delete
#	db_dml delete_old_entry {}
#	# ns_log Notice "$list_id :: $attribute_id"
#	db_exec_plsql ams_list_attribute_map {}
    }
}

ad_proc -public ams::list::attribute::unmap {
    -list_id:required
    -attribute_id:required
} {
    Unmap an ams option from an ams list
} {
    db_dml ams_list_attribute_unmap {}
}

ad_proc -public ams::list::attribute::required {
    -list_id:required
    -attribute_id:required
} {
    Specify and ams_attribute as required in an ams list
} {
    db_dml ams_list_attribute_required {}
}

ad_proc -public ams::list::attribute::optional {
    -list_id:required
    -attribute_id:required
} {
    Specify and ams_attribute as optional in an ams list
} {
    db_dml ams_list_attribute_optional {}
}

ad_proc -public ams::list::attribute::get_mapped_attributes {
    {-list_id ""}
    {-list_name ""}
    -object_type:required
    -package_key:required
} {
    Returns a list of attribute_id's mapped to the list_id. If you provided
    both parameter list_id will be used.
    
    @param list_id     list_id to get mapped attributes from
    @param list_name   list_name to get mapped attributes from
    @param object_type the type of the object mapped to the list 
    @param package_key the package_key to use for get the list_id when list_name is provided.
} {
    if { [empty_string_p $list_id] && [empty_string_p $list_name] } {
	ad_return_complaint 1 "[_ intranet-dynfield.you_must_provide_list_id]"
	ad_scritp_abort
    }
    
    if { ![empty_string_p $list_name] && [empty_string_p $list_id]} {
	set list_id [ams::list::get_list_id -package_key $package_key -object_type $object_type -list_name $list_name]
    }
    
    return [db_list get_attributes { }]
}








