namespace eval contact::employee {}
namespace eval contact::util {}


ad_proc -public contact::employee::get {
    {-employee_id:required}
    {-array:required}
    {-organization_id ""}
    {-package_id ""}
    {-use_cache:boolean}
    {-format "html"}
} {
    Get full employee information. If employee does not have a phone number, fax number, or an e-mail address, the employee will be assigned the corresponding employer value, if an employer exists. Cached.

    @author Al-Faisal El-Dajani (faisal.dajanim@gmail.com)
    @creation-date 2005-10-18
    @param employee_id The ID of the employee whose information you wish to retrieve.
    @param array Name of array to upvar contents into.
    @param organization_id ID of the organization whose information should be returned <I> if </I> the employee_id is an employee at this organization. If not specified, defaults to first employer relationship found, if any.
    @return 1 if user exists, 0 otherwise.

    @return Array-list of data.
    @return first_names First Name of the person
    @return last_name 
    @return salutation Salutation of the person
    @return salutation_letter Salutation for a letterhead
    @return person_title
    @return direct_phoneno Direct phone number of the person, use company one if non existing
    @return directfaxno Direct Fax number, use company one if non existing
    @return email email of the person or the company (if there is no email for this person) 
    @return organization_id of the company (if there is an employing company)
    @return name name of the company (if there is an employing company)
    @return company_name_ext Name extension of the company (if there is one)
    @return address Street of the person (or company)
    @return municipality
    @return region
    @return postal_code
    @return country_code
    @return country Name of the country in the user's locale
    @return town_line TownLine in the format used in the country of the party
    @return locale Locale of the employee
    @return jobtitle Job Title of the person

} {
    upvar $array local_array
    if { $package_id eq "" } {
	set package_id [ad_conn package_id]
    }
    if {$use_cache_p} {
	set values [util_memoize [list ::contact::employee::get_not_cached -employee_id $employee_id -organization_id $organization_id -package_id $package_id -format $format]]
    } else {
	set values [::contact::employee::get_not_cached -employee_id $employee_id -organization_id $organization_id -package_id $package_id -format $format]
    }
    if {![empty_string_p $values]} {
	array set local_array $values
	return 1
    } else {
	return 0
    }
}

ad_proc -private contact::employee::get_not_cached {
    {-employee_id:required}
    {-organization_id}
    {-package_id:required}
    {-format:required}
} {
    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
    Get full employee information. If employee does not have a phone number, fax number, or an e-mail address, the employee will be assigned the corresponding employer value, if an employer exists. Uncached.
    @param employee_id The ID of the employee whose information you wish to retrieve.
    @param organization_id ID of the organization whose information should be returned <I> if </I> the employee_id is an employee at this organization. If not specified, defaults to first employer relationship found, if any.

} {
    # ons_log notice "start processing"
    set employer_exist_p 0
    set employee_attributes [list "first_names" "last_name" "person_title" "directphoneno" "directfaxno" "email" "jobtitle" "person_title"]
    set employer_attributes [list "name" "company_phone" "company_fax" "email" "company_name_ext" "client_id"]

    # Check if ID belongs to an employee, if not return the company information

    if {![person::person_p -party_id $employee_id]} {
	set employer_id $employee_id
	set employer_rev_id [content::item::get_best_revision -item_id $employer_id]
	foreach attribute $employer_attributes {
	    set value [ams::value \
			   -object_id $employer_rev_id \
			   -attribute_name $attribute \
			   -format $format
		      ]
	    switch $attribute {
		company_phone { set attribute "directphoneno" }
		company_fax   { set attribute "directfaxno" }
	    }
	    set local_array($attribute) $value
	}

	set local_array(salutation) "#contacts.lt_dear_ladies_and#"
	set local_array(salutation_letter) "" 
	if {[contacts::postal_address::get -attribute_name "company_address" -party_id $employer_id -array address_array]} {
	    set local_array(address) $address_array(delivery_address)
	    set local_array(municipality) $address_array(municipality)
	    set local_array(region) $address_array(region)
	    set local_array(postal_code) $address_array(postal_code)
	    set local_array(country_code) $address_array(country_code)
            set local_array(country) $address_array(country)
            set local_array(town_line) $address_array(town_line)
	    set company_address_p 1
	}
	return [array get local_array]
    }

    set employee_rev_id [content::item::get_best_revision -item_id $employee_id]

    # Get employers, if any
    set employers [list]
    set employers [contact::util::get_employers -employee_id $employee_id -package_id $package_id]

    # If employer(s) exist
    if {[llength $employers] > 0} {
	if {[exists_and_not_null organization_id]} {
	    # If user sepcified to get information for a certain employer, check if the specified employer exists. If employer specified is not an employer, no organization info will be returned.
	    foreach single_employer $employers {
		if {$organization_id == [lindex $single_employer 0]} {
		    set employer $single_employer
		    set employer_exist_p 1
		    break
		}
	    }
	} else {
	    # If user didn't specify a certain employer, get first employer.
	    set employer [lindex $employers 0]
	    set employer_exist_p 1
	}
	# Get best/last revision
	set employer_id [lindex $employer 0]
	set employer_rev_id [content::item::get_best_revision -item_id $employer_id]
	
	# set the info
	set local_array(organization_id) $employer_id
    }

    set company_address_p 0
    if {$employer_exist_p} {
	foreach attribute $employer_attributes {
	    set value [ams::value \
			   -object_id $employer_rev_id \
			   -attribute_name $attribute \
			   -format $format
		      ]
	    switch $attribute {
		company_phone { set attribute "directphoneno" }
		company_fax   { set attribute "directfaxno" }
	    }
	    set local_array($attribute) $value
	}

	if {[contacts::postal_address::get -attribute_name "company_address" -party_id $employer_id -array address_array]} {
	    set local_array(address) $address_array(delivery_address)
	    set local_array(municipality) $address_array(municipality)
	    set local_array(region) $address_array(region)
	    set local_array(postal_code) $address_array(postal_code)
	    set local_array(country_code) $address_array(country_code)
            set local_array(country) $address_array(country)
            set local_array(town_line) $address_array(town_line)
	    set company_address_p 1
	}
    } else {
	# There is no employer info, so we just return empty values
	set local_array(organization_id) ""
	foreach attribute $employer_attributes {
	    set local_array($attribute) ""
	}
	set local_array(address) ""
	set local_array(municipality) ""
	set local_array(region) ""
	set local_array(postal_code) ""
	set local_array(country_code) ""
	set local_array(country) ""
	set local_array(town_line) ""
    }
    
    # Set the attributes
    # This will overwrite company's attributes
    foreach attribute $employee_attributes {
	set value [ams::value \
		       -object_id $employee_rev_id \
		       -attribute_name $attribute \
		       -format $format
		  ]
	set local_array($attribute) $value
    }

    # Set the salutation
    set local_array(salutation) [contact::salutation_not_cached -party_id $employee_id -type salutation]
    set local_array(salutation_letter) [contact::salutation_not_cached -party_id $employee_id -type letter]

    # As we are asking for employee information only use home_address if there is no company_address
    if {$company_address_p == 0} {
	if {[contacts::postal_address::get -attribute_name "home_address" -party_id $employee_id -array home_address_array]} {
	    set local_array(address) $home_address_array(delivery_address)
	    set local_array(municipality) $home_address_array(municipality)
	    set local_array(region) $home_address_array(region)
	    set local_array(postal_code) $home_address_array(postal_code)
	    set local_array(country_code) $home_address_array(country_code)
            set local_array(country) $home_address_array(country)
            set local_array(town_line) $home_address_array(town_line)
	}
    }

    # message variables. if the employee does not have 
    # a viable mailing address for this package it will
    # look for a viable mailing address for its employers
    set local_array(mailing_address) [contact::message::mailing_address -party_id $employee_id -package_id $package_id]
    set local_array(email_address) [contact::message::email_address -party_id $employee_id -package_id $package_id]


    # Get the locale
    set local_array(locale) [lang::user::site_wide_locale -user_id $employee_id]

    return [array get local_array]
}

ad_proc -public contact::employee::direct_phone {
    {-employee_id:required}
    {-organization_id ""}
    {-package_id ""}
    {-format "html"}
} {
    # Return the directphone of the employee
} {

    if { $package_id eq "" } {
	set package_id [ad_conn package_id]
    }

    set employee_rev_id [content::item::get_best_revision -item_id $employee_id]
    set phone [ams::value \
		   -object_id $employee_rev_id \
		   -attribute_name directphoneno \
		   -format $format
	      ]

    # If we found no phonenumber, but the employee is a person, try organization
    if {$phone == "" && [person::person_p -party_id $employee_id]} {

	# Get employers, if any
	set employers [list]
	set employers [contact::util::get_employers -employee_id $employee_id -package_id $package_id]
	
	# If employer(s) exist
	if {[llength $employers] > 0} {
	    if {[exists_and_not_null organization_id]} {
		# If user sepcified to get information for a certain employer, check if the specified employer exists. 
		# If employer specified is not an employer, no organization info will be returned.
		foreach single_employer $employers {
		    if {$organization_id == [lindex $single_employer 0]} {
			set employer $single_employer
			set employer_exist_p 1
			break
		    }
		}
	    } else {
		# If user didn't specify a certain employer, get first employer.
		set employer [lindex $employers 0]
		set employer_exist_p 1
	    }

	    # Get best/last revision
	    set employer_id [lindex $employer 0]
	    set employer_rev_id [content::item::get_best_revision -item_id $employer_id]
	    set phone [ams::value \
			   -object_id $employer_rev_id \
			   -attribute_name directphoneno \
			   -format $format
		      ]
	}
    }
    return $phone
}
	    


ad_proc -public contact::util::get_employees {
    {-organization_id:required}
    {-package_id ""}
} {
    get employees of an organization
} {
    if { $package_id eq "" } {
	set package_id [ad_conn package_id]
    }
    return [util_memoize [list ::contact::util::get_employees_not_cached -organization_id $organization_id -package_id $package_id]]
}

ad_proc -public contact::util::get_employees_not_cached {
    {-organization_id:required}
    {-package_id:required}
} {
    get employees of an organization
} {
    set contact_list {}
    db_foreach select_employee_ids {
	select CASE WHEN object_id_one = :organization_id
                    THEN object_id_two
                    ELSE object_id_one END as other_party_id
	from acs_rels, acs_rel_types
	where acs_rels.rel_type = acs_rel_types.rel_type
	and ( object_id_one = :organization_id or object_id_two = :organization_id )
	and acs_rels.rel_type = 'contact_rels_employment'
    } {
	if { [contact::visible_p -party_id $other_party_id -package_id $package_id] } {
	    lappend contact_list $other_party_id
	}
    }

    return $contact_list
}

ad_proc -public contact::util::get_employees_list_of_lists {
    {-organization_id:required}
    {-package_id ""}
} {
    get employees of an organization in a list of list suitable for inclusion in options
    the list is made up of employee_name and employee_id. Cached
} {
    if { $package_id eq "" } {
	set package_id [ad_conn package_id]
    }
    return [util_memoize [list ::contact::util::get_employees_list_of_lists_not_cached -organization_id $organization_id -package_id $package_id]]
}

ad_proc -private contact::util::get_employees_list_of_lists_not_cached {
    {-organization_id:required}
    {-package_id:required}
} {
    get employees of an organization in a list of list suitable for inclusion in options
    the list is made up of employee_name and employee_id
} {
    set contact_list [list]
    db_foreach select_employee_ids {
	select CASE WHEN object_id_one = :organization_id
                    THEN object_id_two
                    ELSE object_id_one END as other_party_id
	from acs_rels, acs_rel_types
	where acs_rels.rel_type = acs_rel_types.rel_type
	and ( object_id_one = :organization_id or object_id_two = :organization_id )
	and acs_rels.rel_type = 'contact_rels_employment'
    } {
	if { [contact::visible_p -party_id $other_party_id -package_id $package_id] } {
	    lappend contact_list [list [person::name -person_id $other_party_id] $other_party_id]
	}
    }
    return [lsort -dictionary $contact_list]
    return $contact_list
}

ad_proc -public contact::util::get_employers {
    {-employee_id:required}
    {-package_id ""}
} {
    Get employers of an employee

    @return List of lists, each containing the ID and name of an employer, or an empty list if no employers exist.
} {
    if { $package_id eq "" } {
	set package_id [ad_conn package_id]
    }
    return [util_memoize [list ::contact::util::get_employers_not_cached -employee_id $employee_id -package_id $package_id]]
}

ad_proc -private contact::util::get_employers_not_cached {
    {-employee_id:required}
    {-package_id:required}
} {
    Get employers of an employee

    @author Al-Faisal El-Dajani (faisal.dajani@gmail.com)
    @param employee_id The ID of the employee whom you want to know his/her employer
    @creation-date 2005-10-17
    @return List of lists, each containing the ID and name of an employer, or an empty list if no employers exist.
} {
    set contact_list [list]
    db_list_of_lists select_employer_ids {
	    select CASE WHEN object_id_one = :employee_id
                    THEN object_id_two
                    ELSE object_id_one END as other_party_id, im_company__name(other_party_id) as company_name
	    from acs_rels, acs_rel_types
	    where acs_rels.rel_type = acs_rel_types.rel_type
	    and ( object_id_one = :employee_id or object_id_two = :employee_id )
	    and acs_rels.rel_type = 'contact_rels_employment'
    } 
    return $contact_list
}


ad_proc -public contact::util::get_employee_organization {
    {-employee_id:required}
    {-package_id ""}
} {
    get organization of an employee
} {
    if { $package_id eq "" } {
	set package_id [ad_conn package_id]
    }

    # Make sure the package_id belongs to a contacts package
    if { ![string eq [apm_package_key_from_id $package_id] "contacts"]} {
	set package_id [acs_object::package_id -object_id [content::item::get_best_revision -item_id $employee_id]]
    }

    return [util_memoize [list ::contact::util::get_employee_organization_not_cached -employee_id $employee_id -package_id $package_id]]
}

ad_proc -public contact::util::get_employee_organization_not_cached {
    {-employee_id:required}
    {-package_id:required}
} {
    get organization of an employee
} {
    set contact_list {}
    db_foreach select_employee_ids {
	select object_id_two as other_party_id
	from acs_rels, acs_rel_types
	where acs_rels.rel_type = acs_rel_types.rel_type
	and object_id_one = :employee_id
	and acs_rels.rel_type = 'contact_rels_employment'
    } {
	if { [contact::visible_p -party_id $other_party_id -package_id $package_id] } {
	    lappend contact_list $other_party_id
	}
    }

    return $contact_list
}

namespace eval intranet-contacts::employee {}
ad_proc -public intranet-contacts::employee::create_rel {
} {
    Create the relationship for employees
} {
    db_foreach employee "select person_id, company_id 
        from persons p, im_companies c, acs_rels r, im_biz_object_members bom 
        where object_id_two = person_id 
        and object_id_one = company_id 
        and bom.rel_id = r.rel_id 
        and object_role_id = 1300" {

        contact::util::create_rel -object_id_one $person_id -object_id_two $company_id -rel_type "contact_rels_employment"
  }
}

ad_proc -public intranet-contacts::employee::create_key_account_rel {
} {
    Create the relationship for employees
} {
    db_foreach employee "select person_id, company_id 
        from persons p, im_companies c, acs_rels r, im_biz_object_members bom 
        where object_id_two = person_id 
        and object_id_one = company_id 
        and bom.rel_id = r.rel_id 
        and object_role_id = 1302" {

        contact::util::create_rel -object_id_one $person_id -object_id_two $company_id -rel_type "contact_rels_key_account_mana"
  }
}
    