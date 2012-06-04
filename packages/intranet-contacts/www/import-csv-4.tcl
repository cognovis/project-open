ad_page_contract {
    Save the import files

    @author Malte Sussdorff
    @creation-date 2006-01-13
} {
    file_name:notnull
    file_path:notnull
    {organization:array,multiple,optional}
    {person:array,multiple}
    {contact_rels_employment:array,multiple,optional}
    person_elements
    organization_elements
    contact_rels_employment_elements
    {group_ids ""}
} -properties {
    context:onevalue
    page_title:onevalue
}

ad_progress_bar_begin -title [_ intranet-contacts.Starting_import] -message_1 "[_ intranet-contacts.Import_Running]"

# The usual defaults
set package_id [ad_conn package_id]
set user_id [ad_conn user_id]

# Get the number of elements
set organization_element_count [llength $organization_elements]
set person_element_count [llength $person_elements]
set contact_rels_employment_count [llength $contact_rels_employment_elements]


foreach object_type {person organization contact_rels_employment} {
    foreach element [set ${object_type}_elements] {

	# Retrieve the attribute so we can get the widget
	ams::attribute::get -attribute_id $element -array attribute
	
	# Store the widget in an array so we can reuse it later.
    	set widget($element) $attribute(widget)
    }
}


# Get the CSV File
set csv_stream [open $file_path r]
fconfigure $csv_stream -encoding utf-8
ns_getcsv $csv_stream headers

# Get the header information with ";" as the delimitier
set headers [string trim $headers "{}"]
set headers [split $headers ";"]

# Get the attribute values for the required attributes to create a person / organization
set orga_attribute_id [attribute::id -object_type organization -attribute_name "name"]
set first_names_id [attribute::id -object_type person -attribute_name first_names]
set last_name_id [attribute::id -object_type person -attribute_name last_name]
set email_id [attribute::id -object_type person -attribute_name email]


# Now loop through the CSV Stream as long as there is still a line left.
while {1} {
    set n_fields [gets $csv_stream one_line]
    if {$n_fields == -1} {
	break
    }

    #Place the attributes in a list
    package require csv
    set value_list [csv::split $one_line ";"]
    for {set i 0} {$i < $n_fields} {incr i} {
	set header [lindex $headers $i]
	regsub -all { } $header {_} header
	set values($header) [lindex $value_list $i]
    }


    append html "$one_line<br/>"
    ############
    # Deal with the organization
    ############
    set existing_organizations ""
    set organization_revision_id ""
    set organization_id ""
    set person_id ""
    set person_revision_id ""
    set existing_persons ""

    if {[exists_and_not_null organization($orga_attribute_id)]} {
	set column [set organization($orga_attribute_id)]
	if {[exists_and_not_null values($column)]} {
	    set organization_name $values($column)
	    
	    # Figure out if this organization already exists.
	    set existing_organization_ids [db_list check_existing_orgas {select organization_id from organizations where name = :organization_name }   ]
	    if {[llength $existing_organization_ids] == 0} {
		#organization does not exist, create it
		append html "Create orga:: $organization_name <br/>"
		set organization_id [organization::new -name $organization_name]
		set organization_revision_id [contact::revision::new -party_id $organization_id]
	    
	    } else {
		# If organization already exists, get first id
		append html "existing orga:: $organization_name<br/>"
		set organization_id [lindex $existing_organization_ids 0]
		set organization_revision_id [content::item::get_best_revision -item_id $organization_id]
	    }
	    
	    if {$organization_id ne ""} {
		# Add to the groups
		foreach group_id $group_ids {
		    set rel_id [db_string existing_rel { select rel_id from acs_rels where rel_type = 'organization_rel' and object_id_one = :group_id and object_id_two = :organization_id } -default 0]
		    if {$rel_id eq 0} {
			set rel_id [db_string insert_rels2 { select acs_rel__new (NULL::integer,'organization_rel',:group_id,:organization_id,NULL,NULL,NULL) as org_rel_id }]
		db_dml insert_state2 { insert into membership_rels (rel_id,member_state) values (:rel_id,'approved') }
			append html "Added to group_id :: $group_id"
		    }
		}
	    }
	}
    }

    ##########
    # Deal with person
    ##########

    # Set the person elements
    foreach person_element {first_names last_name email} {
	# set the default 
	set $person_element " "
	if {[exists_and_not_null person([set ${person_element}_id])]} {
	    set column [set person([set ${person_element}_id])]
	    if {[exists_and_not_null values($column)]} {
		set $person_element $values($column)
	    }
	}
    }


    # Cheack if the person exists
    if {$email ne " "} {
	set person_id [party::get_by_email -email $email]
    } else {
	set person_id ""
	set email ""
    }

    if {$person_id eq ""} {
	set existing_person_ids [db_list check_existing_persons {select party_id from parties, persons where party_id = person_id and last_name = :last_name and first_names = :first_names}]
	
	# Check if the person is employed by company
	# Stop at the first person.
	foreach existing_person_id $existing_person_ids {
	    if {[contact::util::get_employee_organization -employee_id $existing_person_id] eq $organization_id} {
		set person_id $existing_person_id
		break
	    }
	}
    }

    append html "PERSON $person_id :: $first_names :: $last_name :: $email<br/>"

    # Create new. This needs ammendment later
    if {$person_id eq "" && ( $first_names ne "" || $last_name ne "")} {

	set person_id [person::new \
			   -first_names $first_names \
			   -last_name $last_name \
			   -email $email]

	# todo: set correct locale
	callback contact::person_add -package_id $package_id -person_id $person_id

	# Add to the groups
	foreach group_id $group_ids {
	    group::add_member \
		-group_id $group_id \
		-user_id $person_id \
		-rel_type "membership_rel"
	}
    }    

    #set revision_id to newly created revision for this party_id
    set person_revision_id [contact::revision::new -party_id $person_id]

    # And now create the relationship
    if {$organization_id ne "" && $person_id ne ""} {
	set contact_rels_employment_revision_id [relation_add "contact_rels_employment" $person_id $organization_id]
    }

    # And now append the values
    foreach object_type {person organization contact_rels_employment} {
	if {[exists_and_not_null ${object_type}_revision_id]} {
	    set revision_id [set ${object_type}_revision_id]
	} else {
	    break
	}

	foreach attribute_id [set ${object_type}_elements] {

	    # Differentiate between the widgets
	    switch $widget($attribute_id) {
		postal_address {
		    # Here we have to deal again with the postal_address
		    
		    # Let's assume by default we are not going to save
		    # the address
		    set save_p 0

		    # Initialize the variable
		    foreach address_part {delivery_address postal_code municipality region country_code country} {
			set $address_part ""
			# Check if a match was made
			
			if {[exists_and_not_null ${object_type}(${attribute_id}_${address_part})]} {
			    # Column is the name of the header in the CSV
			    set column [set ${object_type}(${attribute_id}_${address_part})]
			    if {[exists_and_not_null values($column)]} {
				append html "$values($column) - " 
				set $address_part $values($column)
				# We have something in the address, so
				# save it.
				set save_p 1
			    } else {
				set $address_part ""
			    }
			}
		    }
		    
		    # Now make the country a country code
 		    if {![exists_and_not_null country_code]} {
			if {[exists_and_not_null country]} {
			    # We do have the country, so let's figure
			    # out the code for it.
			    set country_code [db_string country_code "select iso from country_codes where country_name = :country"]
			} elseif {$save_p} {
			    set country_code [lindex [parameter::get_from_package_key -parameter "DefaultISOCountryCode" -package_key "ams" -default ""] 0]
			}
		    }

		    # Now save it
		    if {$country_code ne ""} {
			set country_code [string toupper $country_code]
			append html "postal:: $country_code $municipality<br />"
			ams::attribute::save::postal_address -object_id [set ${object_type}_revision_id] \
			    -attribute_id $attribute_id -object_type $object_type  -delivery_address $delivery_address \
			    -municipality $municipality  -region $region -postal_code $postal_code -country_code $country_code 
		    }		
		}
		date {
		    # Date widgets
		    if {[exists_and_not_null ${object_type}($attribute_id)]} {
			set column [set ${object_type}($attribute_id)]
			if {[exists_and_not_null values($column)]} {
			    if {[regexp {^([0-9]+)\.([0-9]+)\.([0-9]+)$} $values($column) match day month year]} {
				append html "DATE SAVED: $values($column) :: $person_id"
				ams::attribute::save::timestamp -object_id [set ${object_type}_revision_id] -attribute_id $attribute_id -object_type $object_type -day $day -year $year -month $month -hour 00 -minute 00
			    }
			}
		    }
		}
		telecom_number - mobile_number {
		    # Phone Attributes
		    if {[exists_and_not_null ${object_type}($attribute_id)]} {
			set column [set ${object_type}($attribute_id)]
			if {[exists_and_not_null values($column)]} {
			    ams::attribute::save::simple_phone_number -object_id [set ${object_type}_revision_id] -attribute_id $attribute_id -phone_number $values($column) -object_type $object_type
			}
		    }
		}
		checkbox - select - multiselect {
		    # Multiple Choice
		    if {[exists_and_not_null ${object_type}($attribute_id)]} {
			set column [set ${object_type}($attribute_id)]
			if {[exists_and_not_null values($column)]} {
			    ams::attribute::save::mc -object_id [set ${object_type}_revision_id] -attribute_id $attribute_id -value $values($column) -object_type $object_type
			}
		    }
		}
		integer {
		    # Number type widgets
		    if {[exists_and_not_null ${object_type}($attribute_id)]} {
			set column [set ${object_type}($attribute_id)]
			if {[exists_and_not_null values($column)]} {
			    ams::attribute::save::number -object_id [set ${object_type}_revision_id] -attribute_id $attribute_id -number $values($column) -object_type $object_type
			}
		    }
		}
		textbox - textarea - richtext - url - skype - default {
		    # Text type widgets
		    if {[exists_and_not_null ${object_type}($attribute_id)]} {
			set column [set ${object_type}($attribute_id)]
			if {[exists_and_not_null values($column)]} {
			    ams::attribute::save::text -object_id [set ${object_type}_revision_id] -attribute_id $attribute_id \
				-value $values($column) -object_type $object_type
			}
		    }
		}
	    }
	}
    }

}

ad_progress_bar_end -url "[ad_conn package_url]"

