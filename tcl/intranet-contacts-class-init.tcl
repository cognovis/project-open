ad_library {
	
    @creation-date 2008-08-09
    @author  (malte.sussdorff@cognovis.de)
    @cvs-id 
}

# Initialize all rel classes if they don't exist already
# First get the object_types
set object_types [db_list object_types "select object_type from acs_object_types where supertype = 'contact_rel'"]

foreach object_type $object_types {
    if {![::xotcl::Object isclass [::im::dynfield::Class object_type_to_class $object_type]]} {
        # Apparently the relationship has no attributes attached to it.
        # Thats why intranet-dynfield has not generated the class for it yet.
        ::im::dynfield::Class get_class_from_db -object_type $object_type
    }
}

set object_types [db_list object_types "
	select object_type 
	from acs_object_types 
	where supertype = 'im_biz_object_member'
UNION
	select 'person'
"]

foreach object_type $object_types {
    if {![::xotcl::Object isclass [::im::dynfield::Class object_type_to_class $object_type]]} {
        # Apparently the relationship has no attributes attached to it.
        # Thats why intranet-dynfield has not generated the class for it yet.
        ::im::dynfield::Class get_class_from_db -object_type $object_type
    }
}



::im::dynfield::Class::person ad_instproc list_ids {} {
    For persons we work based on groups, so we need to find the lists
    based on the group name
} {
    set list_names [list "person"]
    # This is a person, therefore we deal with group based lists
    if {[catch {set groups_belonging_to [db_list get_party_groups " select group_id from group_distinct_member_map where member_id = [my object_id] "]}]} {
        set groups_belonging_to ""
    }

    set package_id [apm_package_id_from_key "intranet-contacts"]
    set ams_groups [list]
    foreach group [contact::groups -expand "all" -privilege_required "read" -package_id $package_id -all] {
        set group_id [lindex $group 1]
        if { [lsearch $groups_belonging_to $group_id] >= 0 } {
            lappend ams_groups $group_id
        }
    }
    
    foreach group_id $ams_groups {
         set form "${package_id}__${group_id}"
         lappend list_names [list $form]
    }
    
    return [db_list list_ids "select category_id from im_categories where category in ([template::util::tcl_to_sql_list $list_names])"]
}

if {0} {
::im::dynfield::Form::user ad_instproc on_submit {} {
    This will automatically set the empty username and screen_name
} {
    # Complete variables with defaults if necessary
    if {![exists_and_not_null username]} { set username $email }
    if {![exists_and_not_null screen_name]} { set screen_name "$first_names $last_name" }
    next
}
}

::im::dynfield::Form::im_company ad_instproc on_submit {} {
    Set default values 
} {
    my instvar data
    $data instvar company_status_id company_type_id company_path
    if {![exists_and_not_null company_status_id]} { $data set company_status_id [im_company_status_active] }
    if {![exists_and_not_null company_type_id]} { $data set company_type_id [im_company_type_other] }

    # Create the company_path from company_name
    if {![exists_and_not_null company_path]} { 
        set company_path [string tolower [string trim $company_name]]
        regsub -all " " $company_path "_" company_path
        $data set company_path $company_path
    }    
}

::im::dynfield::Form::im_office ad_instproc new_data {} {
    Set the default values and even set the main_office_id
} {
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


    if {![$data exists office_status_id]} { $data set office_status_id [im_office_status_active] }
    if {![$data exists office_type_id]} { $data set office_type_id [im_office_type_main] }

    # Create the office_path from company_name
    if {![$data exists office_path]} { 
	set office_path [string tolower [string trim [$data office_name]]]
	regsub -all " " $office_path "_" office_path
	if {[string length $office_path] >100} { 
	    set office_path [string range $office_path 0 99]
	}
	$data set office_path $office_path
    }

    ds_comment [$data serialize]
    $data initialize_loaded_object
    $data save_new
    return [$data set object_id]
}

::im::dynfield::Form::im_company ad_instproc after_submit {} {
    Add the creation user as key_account to the company
} {
    my instvar data
    set user_id [ad_conn user_id]
    # add users to the company as key account
    set role_id [im_biz_object_role_full_member]
    im_biz_object_add_role $user_id [$data set company_id] $role_id
    next
}


::im::dynfield::Form::person ad_instproc after_submit {} {
    This will add the party to the groups, gotten from the list ids
} {
    my instvar data list_ids
    $data instvar person_id company_id
    set group_ids ""
    set contacts_package_id [apm_package_id_from_key "intranet-contacts"]

    # Get the group_ids from the lists
    db_foreach list_names "select category from im_categories where category_id in ([template::util::tcl_to_sql_list $list_ids]) and category like '${contacts_package_id}__%'" {
        set group_id [lindex [split $category "__"] 1]
        lappend group_ids $group_id
    }

    foreach group_id $group_ids {
	    contact::group::add_member \
	        -group_id $group_id \
	        -user_id "$person_id" \
	        -rel_type "membership_rel"
    }
    next
}


if {[lsearch [::im::dynfield::Class::person info instprocs] address] < 0} {
::im::dynfield::Class::person ad_instproc address {
    {-type "home"}
} {
    Returns a list with the address information
    
    
} {
    if {$type eq "home"} {
	my set address_line1 [my ha_line1]
	my set address_line2 [my ha_line2]
	my set city [my ha_city]
	my set postal_code [my ha_postal_code]
	my set state [my ha_state]
	my set country_code [my ha_country_code]
	my set company_name ""
    }
    
    set country_code [my set country_code]
    my set country [db_string country "select country_name from country_codes where iso = :country_code" -default ""]
    my set city_line "[my set postal_code] [my set city]"
    my set address_name "[my first_names] [my last_name]"
    my set salutation "[my set salutation_id_deref] [my set last_name]"

    # Get linked office
    set office_id [db_string office_id "select object_id_one from acs_rels where object_id_two = [my object_id] and rel_type = 'office_member_rel' limit 1" -default ""]
    my set fax "[db_string fax "select fax from im_offices where office_id = :office_id" -default ""]"
}
}