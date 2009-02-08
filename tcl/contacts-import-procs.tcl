namespace eval contacts::import:: {}

ad_proc -public contacts::import::csv {
    -filename
    {-group_name ""}
    {-locale "en_US"}
    {-overwrite_customer_p 0}
    {-contacts_package_id ""}
} {
    Imports leads information from a file. This procedure still has a couple of things that need to be done to make it generally useful.

    - The mapping of the Elements from the CSV file id hard coded at the moment and not really internationalized. Here someone should replace the "E-Mail" and "Firma" with "[_ intranet-contacts.csv_email]" and "[_ intranet-contacts.csv_name]"

    @author Malte Sussdorff (malte.sussdorff@cognovis.de)

    @param filename name of CSV file containing the clients information to be imported. Note. The delimiter is ";" !!
    @param group_name Name of the group where the import should take them.
    @param locale Locale of the users who will be imported to the system
    @param overwrite_customer_p Overwrite existing organization data even for customers ?

    @creation-date 2006-12-07
} {

    set person_date_list [list \
		       [list "GebDat" "birthdate"]
		   ]


    set organization_text_list [list \
				    [list "Firma" "name"] \
				    [list "Zusatz" "company_name_ext"] \
				    [list "Internet" "company_url"] \
				    [list "E-Mail3" "organization_email"] \
			       ]


    set person_text_list [list \
			      [list "E-Mail" "email"] \
			      [list "E-Mail2" "alternative_email"] \
			      [list "Vorname" "first_names"] \
			      [list "Nachname" "last_name"] \
			      [list "Position" "jobtitle"] \
			      [list "Titel" "person_title"] \
			      [list "Abteilung" "department"] \
			      [list "Bemerkung" "person_notes"] \
			 ]

    set organization_mc_list [list \
				  [list "Branche" "industrysector"] \
				  [list "Symbol" "lead_state"] \
				 ]

    set organization_phone_list [list \
				     [list "Telefon2" "company_phone"] \
				     [list "Telefax" "company_fax"]
				]

    set person_phone_list [list \
			       [list "Telefon1" "directphoneno"] \
			       [list "Mobiltelefon" "mobile_phone"] \
			       [list "Ptelefon1" "private_phone"] \
			       [list "Ptelefon2" "telephone_other"] \
			       [list "Ptelefax" "private_fax"] 
			  ]

    
    # Get the CSV File
    set csv_stream [open $filename r]
    fconfigure $csv_stream -encoding utf-8
    ns_getcsv $csv_stream headers

    # Get the header information with ";" as the delimitier
    set headers [string trim $headers "{}"]
    set headers [split $headers ";"]

    set person_count 0
    set organization_count 0

    if {$contacts_package_id eq ""} {
	set contacts_package_id [apm_package_id_from_key "contacts"]
    }

    set default_group_id [contacts::default_group -package_id $contacts_package_id]
    set group_id [group::get_id -group_name "$group_name"]
    set customer_group_id [group::get_id -group_name "Customers"]
    set salutation_attribute_id [attribute::id -object_type person -attribute_name salutation]

    db_foreach salutation_options {
	select option, option_id
	from ams_option_types
	where attribute_id = :salutation_attribute_id
    } {
	set salutation($option) $option_id
    }

    # Now loop through the CSV Stream as long as there is still a line left.
    while {1} {
	set n_fields [gets $csv_stream one_line]
	if {$n_fields == -1} {
	    break
	}

	#Place the attributes in a list
	set one_line [string trim $one_line "{}"]
	set one_line [split $one_line ";"]
	set n_fields [llength $one_line]

	for {set i 0} {$i < $n_fields} {incr i} {
	    set values([lindex $headers $i]) [string trim [string trim [lindex $one_line $i] "\""]]
	}

	# Make sure mandatory fields are set.
	if {![exists_and_not_null values(E-Mail)]} {
	    set email ""
	    set values(E-Mail) ""
	} else {
	    set email $values(E-Mail)
	}
	
	if {![exists_and_not_null values(Vorname)]} {
	    set first_names " "
	    set values(Vorname) ""
	} else {
	    set first_names $values(Vorname)
	}
	
	if {![exists_and_not_null values(Nachname)]} {
	    set last_name " "
	    set values(Nachname) ""
	} else {
	    set last_name $values(Nachname)
	}

	if {![exists_and_not_null values(Pstrasse)]} {
	    set values(PStrasse) ""
	}
	
	if {![exists_and_not_null values(Port)]} {
	    set values(POrt) ""
	}
	
	if {![exists_and_not_null values(PPLZ)]} {
	    set values(PPLZ) ""
	}
	
	if {![exists_and_not_null values(Pland)]} {
	    set values(PLand) "DE"
	}
	
	if {![exists_and_not_null values(Pbundesland)]} {
	    set values(PBundesland) ""
	}
	
	# Company information
	if {![exists_and_not_null values(Telefon1)]} {
	    set values(Telefon1) ""
	}
	
	if {![exists_and_not_null values(Strasse)]} {
	    set values(Strasse) ""
	}
	
	if {![exists_and_not_null values(Ort)]} {
	    set values(Ort) ""
	}
	
	if {![exists_and_not_null values(PLZ)]} {
	    set values(PLZ) ""
	}
	
	if {![exists_and_not_null values(Land)]} {
	    set values(Land) "DE"
	}
	
	if {![exists_and_not_null values(Bundesland)]} {
	    set values(Bundesland) ""
	}
	
	if {![exists_and_not_null values(Internet)]} {
	    set values(Internet) ""
	}
	
	if {![exists_and_not_null values(Firma)]} {
	    set organization_name ""
	} else {
	    set organization_name $values(Firma)
	}

	if {![exists_and_not_null values(E-Mail3)]} {
	    set organization_email ""
	} else {
	    set organization_email $values(E-Mail3)
	}

	# If there is no company phone, set to person phone
	if {![exists_and_not_null values(Telefon2)]} {
	    set values(Telefon2) $values(Telefon1)
	}
	
	# Get Prof. and Dr. out of the way if they are in the name (title)
	
	foreach name {Vorname Nachname} {
	    foreach prefix {Dr. Prof.} {
		if {[string first $prefix $values($name)] > -1} {
		    if {![exists_and_not_null values(Titel)]} {
			set values(Titel) $prefix
		    }
		    set values($name) [string trim [string map [list "$prefix" ""] $values($name)]]
		}
	    }
	}

	# Get the salutation option correct
	if {[exists_and_not_null values(Anrede)]} {

	    # Okay, here we are cheating. We assume there exists a field Anrede / Gender which contains "Frau" if it is female and
	    # something else otherwise. Obvioulsy this would need some I18N Modifications as well.
	    if {$values(Anrede) != "Frau"} {
		set values(Geschlecht) "M"
		set values(Briefanrede) "Dear Mr. "
	    } else {
		set values(Geschlecht) "F"
		#2006/11/20 (Option 2310 deleted) set values(Briefanrede) "Dear Ms. "
		set values(Briefanrede) "Dear Mrs. "
	    }
	}

	############
	# check if organization exists with same name and zipcde
	############
	
	set existing_organization_ids [db_list check_existing_orgas {select organization_id from organizations where name = :organization_name }
				      ]
	set existing_organizations ""
	set organization_revision_id ""
	set organization_id ""
	
	if {![string eq [string trim $organization_name] ""]} {
	    foreach organization_id $existing_organization_ids {
		contacts::postal_address::get -attribute_name "company_address" -party_id $organization_id -array address_array
		if {[exists_and_not_null address_array(postal_code)] && $values(PLZ) == $address_array(postal_code)} {
		    lappend existing_organizations $organization_id
		}
	    }

	    # set orga_p [organization::name_p -name $values(Firma)]
	    
	    if {[llength $existing_organizations] == 0} {
		#if organization does not exist, create it
		set organization_id [organization::new -name $organization_name -email $organization_email -url $values(Internet)]
		ns_log Notice "contacts::import::leads => Organization created $organization_name: $organization_id"
		
		set organization_revision_id [contact::revision::new -party_id $organization_id]
		
		# Add to the default group
		set rel_id [db_string insert_rels { select acs_rel__new (NULL::integer,'organization_rel',:default_group_id,:organization_id,NULL,NULL,NULL) as org_rel_id }]
		db_dml insert_state { insert into membership_rels (rel_id,member_state) values (:rel_id,'approved') }
		
		# Add to the other group
		if {$group_id ne ""} {
		    set rel_id [db_string insert_rels2 { select acs_rel__new (NULL::integer,'organization_rel',:group_id,:organization_id,NULL,NULL,NULL) as org_rel_id }]
		    db_dml insert_state2 { insert into membership_rels (rel_id,member_state) values (:rel_id,'approved') }
		}

		# set creation_date if "DatumErfassst" contains it
		# THis allows for import from other sources
		if {[exists_and_not_null values(DatumErfasst)]} {
		    set value $values(DatumErfasst)
		    ns_log notice $value
		    regexp {^([0-9]+)\.([0-9]+)\.([0-9]+)$} $value match day month year
		    if {[exists_and_not_null month]} {
			set date_string "$year-$month-$day 00:00"
			unset month
			# NOTE
			# here we update the creation_date of the ORGANIZATION_ID
			# with the value of "DatumErfasst", if set
			# /NOTE
			db_dml update_creation_date {
			    update cr_revisions
			    set publish_date = to_timestamp(:date_string, 'YYYY-MM-DD HH24:MI')
			    where revision_id = :organization_revision_id
			}
		    }
		}
		
	    } else {
		# If organization already exists, get first id
		set organization_id [lindex $existing_organizations 0]
		
		# check if organization is customer and do not import
		if {[db_0or1row check_if_customer {
		    select 1
		    from membership_rels m, acs_rels r
		    where m.rel_id = r.rel_id
		    and r.object_id_one = :customer_group_id
		    and r.object_id_two = :organization_id
		    and r.rel_type = 'organization_rel'
		}] && !$overwrite_customer_p} {
		    ns_log Notice "contacts::import::leads => Organization is customer $values(Firma): $organization_id"
		    continue
		} else {
		    set organization_revision_id [content::item::get_best_revision -item_id $organization_id]
		    ns_log Notice "contacts::import::leads => Organization exists $values(Firma): $organization_id"
		}
	    }
	    
	    if {![string eq "" $organization_revision_id]} {
		
		# Set organization text attributes
		foreach pair $organization_text_list {
		    set attribute [lindex $pair 0]
		    set attribute_name [lindex $pair 1]
		    if {[exists_and_not_null values($attribute)]} {
			set value [string trim $values($attribute)]
			ams::attribute::save::text \
			    -object_id $organization_revision_id \
			    -attribute_name $attribute_name \
			    -object_type "organization" \
			    -value $value
		    }
		}
		
		# Set organization phone attributes
		foreach pair $organization_phone_list {
		    set attribute [lindex $pair 0]
		    set attribute_name [lindex $pair 1]
		    if {[exists_and_not_null values($attribute)] && $values($attribute) != "0"} {
			set value $values($attribute)
			set value_id [ams::util::telecom_number_save -subscriber_number $value]
			set attribute_id [attribute::id -object_type "organization" -attribute_name $attribute_name]
			ams::attribute::value_save \
			    -attribute_id $attribute_id \
			    -value_id $value_id \
			    -object_id $organization_revision_id
		    }
		}
		
		# Set the organization mc attributes
		foreach pair $organization_mc_list {
		    set attribute [lindex $pair 0]
		    set attribute_name [lindex $pair 1]
		    if {[exists_and_not_null values($attribute)]} {
			set value $values($attribute)
			ams::attribute::save::mc \
			    -object_id $organization_revision_id \
			    -attribute_name "$attribute_name" \
			    -object_type "organization" \
			    -value "$value"
		    }
		}
	    
		# set organization address attributes
		set Adresse $values(Strasse)
		set Ort $values(Ort)
		set Postleitzahl $values(PLZ)
		set Land $values(Land)
		set bundesland $values(Bundesland)
		if {$Land == "D"} {
		    set Land "DE"
		}
		
		if {[string length $Land]>2} {
		    set Land [ref_countries::get_country_code -country $Land]
		}

		if {$Land == "DE" || $Land == "AT"} {
		    set locale "de_DE"
		} elseif {$Land == "CH"} {
		    set locale "de_CH"
		} else {
		    set locale "en_US"
		}

		if {![string eq "" $Adresse] && ![string eq "" $Land]} {
		    set value_id [ams::util::postal_address_save \
				      -delivery_address $Adresse \
				      -municipality $Ort \
				      -postal_code $Postleitzahl \
				      -country_code $Land \
				      -region $bundesland
				 ]
		    set attribute_id [attribute::id \
					  -object_type "organization" \
					  -attribute_name "company_address"
				     ]
		    ams::attribute::value_save \
			-object_id $organization_revision_id \
			-attribute_id $attribute_id \
			-value_id $value_id
		}

		# set creation_date
		if {[exists_and_not_null values(DatumErfasst)]} {
		    set value $values(DatumErfasst)
		    ns_log notice $value
		    regexp {^([0-9]+)\.([0-9]+)\.([0-9]+)$} $value match day month year
		    if {[exists_and_not_null month]} {
			set date_string "$year-$month-$day 00:00"
			unset month
			# NOTE
			# here we update the creation_date of the PERSON_ID
			# with the value of "DatumErfasst", if set
			# /NOTE
			db_dml update_creation_date {
			    update cr_revisions
			    set publish_date = to_timestamp(:date_string, 'YYYY-MM-DD HH24:MI')
			    where revision_id = :organization_revision_id
			}
		    }
		}

		incr organization_count
		
	    }
	}
	    




	############
	# if organization existed: check if person exists in any of these organizations
	############
	
	set person_id [party::get_by_email -email $email]
	
	set person_revision_id [content::item::get_best_revision -item_id $person_id]
	
	# Only create new persons. Do not update existing ones (too risky)
	if {$person_revision_id eq ""} {
	    #if there is no party_id
	    if {$person_id eq ""} {
		set person_id [person::new \
				   -first_names $first_names \
				   -last_name $last_name \
				   -email $email]
	    }

	    ns_log Notice "contacts::import::csv => Person created $first_names $last_name ($email): $person_id"
	    
	    # todo: set correct locale
	    callback contact::person_add -package_id $contacts_package_id -person_id $person_id
	    
	    contact::group::add_member \
		-group_id $default_group_id \
		-user_id $person_id \
		-rel_type "membership_rel"
	    
	    if {$group_id ne ""} {
		contact::group::add_member \
		    -group_id $group_id \
		    -user_id $person_id \
		    -rel_type "membership_rel"
	    }

	    #set revision_id to newly created revision for this party_id
	    set person_revision_id [contact::revision::new -party_id $person_id]

	    # set creation_date
	    if {[exists_and_not_null values(DatumErfasst)]} {
		set value $values(DatumErfasst)
		ns_log notice $value
		regexp {^([0-9]+)\.([0-9]+)\.([0-9]+)$} $value match day month year
		if {[exists_and_not_null month]} {
		    set date_string "$year-$month-$day 00:00"
		    unset month
		    # NOTE
		    # here we update the creation_date of the PERSON_ID
		    # with the value of "DatumErfasst", if set
		    # /NOTE
		    db_dml update_creation_date {
			update cr_revisions
			set publish_date = to_timestamp(:date_string, 'YYYY-MM-DD HH24:MI')
			where revision_id = :person_revision_id
		    }
		}
	    }

	    # Set date attributes
	    foreach pair $person_date_list {
		set attribute [lindex $pair 0]
		set attribute_name [lindex $pair 1]
		if {[exists_and_not_null values($attribute)]} {
		    set value $values($attribute)
		    regexp {^([0-9]+)\.([0-9]+)\.([0-9]+)$} $value match day month year
		    set value_id [ams::util::time_save -time "$month-$day-$year 00:00"]
		    set attribute_id [attribute::id \
					  -object_type "person" \
					  -attribute_name $attribute_name
				     ]
		    ams::attribute::value_save \
			-object_id $person_revision_id \
			-attribute_id $attribute_id \
			-value_id $value_id
		}
	    }
	    
	    # Set the text attributes
	    foreach pair $person_text_list {
		set attribute [lindex $pair 0]
		set attribute_name [lindex $pair 1]
		if {[exists_and_not_null values($attribute)]} {
		    set value $values($attribute)
		    ams::attribute::save::text \
			-object_id $person_revision_id \
			-attribute_name $attribute_name \
			-object_type "person" \
			-value $value
		}
	    }
	    
	    # save salutation attribute
	    if {[exists_and_not_null values(Briefanrede)]} {
		set option_id $salutation($values(Briefanrede))
		set value_id [ams::util::options_save -options $option_id]
		
		ams::attribute::value_save \
		    -object_id $person_revision_id \
		    -attribute_id $salutation_attribute_id \
		    -value_id $value_id
	    }
	    
	    # Set phone attributes
	    foreach pair $person_phone_list {
		set attribute [lindex $pair 0]
		set attribute_name [lindex $pair 1]
		if {[exists_and_not_null values($attribute)] && $values($attribute) != "0"} {
		    set value $values($attribute)
		    set value_id [ams::util::telecom_number_save \
				      -subscriber_number $value
				 ]
		    set attribute_id [attribute::id \
					  -object_type "person" \
					  -attribute_name $attribute_name
				     ]
		    ams::attribute::value_save \
			-attribute_id $attribute_id \
			-value_id $value_id \
			-object_id $person_revision_id
		}
	    }
	    
	    # set person address attributes
	    set Adresse $values(Pstrasse)
	    set Ort $values(Port)
	    set Postleitzahl $values(PPLZ)
	    set Land $values(Pland)
	    set bundesland $values(Pbundesland)
	    if {$Land == "D"} {
		set Land "DE"
	    }
	    
	    if {[string length $Land]>2} {
		set Land [ref_countries::get_country_code -country $Land]
	    }
	    
	    if {$Land == "DE" || $Land == "AT"} {
		set locale "de_DE"
	    } elseif {$Land == "CH"} {
		set locale "de_CH"
	    } else {
		set locale "en_US"
	    }
	    
	    
	    if {![string eq "" $Adresse] && ![string eq "" $Land]} {
		set value_id [ams::util::postal_address_save \
				  -delivery_address $Adresse \
				  -municipality $Ort \
				  -postal_code $Postleitzahl \
				  -country_code $Land \
				  -region $bundesland
			     ]
		set attribute_id [attribute::id \
				      -object_type "person" \
				      -attribute_name "visitaddress"
				 ]
		ams::attribute::value_save \
		    -object_id $person_revision_id \
		    -attribute_id $attribute_id \
		    -value_id $value_id
	    }
	}

		
	if {$organization_id ne "" && $person_id ne ""} {
	    relation_add "contact_rels_employment" $person_id $organization_id
	}

	array unset values
    }
}
