ad_library {

	Library to deal with the lists
	
	A list is an arbitrary construct using im_categories
	
    @creation-date 2008-08-22
    @author  (malte.sussdorff@cognovis.de)
    @cvs-id 
}

# Get the OpenACS version
set ver_sql "select substring(max(version_name),1,3) from apm_package_versions where package_key = 'acs-kernel'"
set openacs54_p [string equal "5.4" [util_memoize [list db_string ver $ver_sql ]]]

if {$openacs54_p} {

    ::xotcl::Class create ::im::dynfield::List \
	-slots {
	    xo::Attribute create list_name
	    xo::Attribute create list_id
	    xo::Attribute create object_type
	    xo::Attribute create pretty_name
	    xo::Attribute create description
	    xo::Attribute create list_type
	} -ad_doc {
	    ::im::dynfield::Lists is the class to handle the "ams" lists correctly. It is based on im_categories and 
	    special naming conventions there. Handle with care ...
	}


::im::dynfield::List ad_proc get_instance_from_db {
    -id
} {
    Initialize a list with data from the db
} {
    set r [::im::dynfield::List create ::$id]
    $r db_1row dbq..get_instance "select category as list_name, category_id as list_id, object_type, aux_string1 as pretty_name, category_description as description, category_type as list_type from im_categories, acs_object_types where category_type = type_category_type and category_id = '$id'"
    if {[$r pretty_name] == ""} {
        $r set pretty_name [$r list_name]
    }
    $r destroy_on_cleanup
    return $r
}

::im::dynfield::List ad_instproc url {
} {
    Get a list_url which redirects to the list overview page
} {
    set list_id [my set list_id]
    return [export_vars -base "/intranet-dynfield/list" -url {list_id}]
}

}


namespace eval ams:: {}
namespace eval ams::list:: {}

ad_proc -private ams::list::get_list_id {
    -object_type:required
    -list_name:required
} {
    return the list_id for the given parameters. Chached.
    @return list_id if none exists then it returns blank
} {
    return [db_string get_list_id {} -default {}]
}



ad_proc -private ams::list::exists_p {
    -object_type:required
    -list_name:required
} {
    does an ams list like this exist?

    @return 1 if the list exists for this object_type and package_key and 0 if the does not exist
} {
    set list_id [ams::list::get_list_id -object_type $object_type -list_name $list_name]
    if { [exists_and_not_null list_id] } {
        return 1
    } else {
        return 0
    }
}

ad_proc -public ams::list::url {
    -object_type
    -list_name:required
} {
    Get the URL for a list
} {
    set list_id [ams::list::get_list_id -object_type $object_type -list_name $list_name]
    if {$list_id == ""} {
        return [export_vars -base "/intranet-dynfield/list" -url {list_name object_type}]        
    } else {
        return [export_vars -base "/intranet-dynfield/list" -url {list_id}]
    }

}

ad_proc -public ams::list::get_id {
    -attribute_id
} {
    Get the list_id for the object_type
    
    @attribute_id dynfield_attribute_id
} {
    set subtype_id [db_string subtype "select object_type_id from im_dynfield_type_attribute_map where attribute_id = :attribute_id limit 1" -default ""]
    if {$subtype_id eq ""} {
        set object_type [db_string object_type "select object_type from acs_attributes aa, im_dynfield_attributes ida where ida.acs_attribute_id = aa.attribute_id and ida.attribute_id = :attribute_id"]
        set subtype_id [ams::list::get_list_id -object_type $object_type -list_name $object_type]
    }
    return $subtype_id
}