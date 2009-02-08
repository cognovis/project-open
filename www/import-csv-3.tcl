ad_page_contract {
    Page to upload files and generate new task for dpm/fpm

    @author Timo Hentschel (timo@timohentschel.de)
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

# Get the number of elements
set organization_element_count [llength $organization_elements]
set person_element_count [llength $person_elements]
set contact_rels_employment_count [llength $contact_rels_employment_elements]

set html "<table border=2><tr><td colspan=\"$person_element_count\">Person</td><td colspan=\"$organization_element_count\">Organisation</td>"
if {$contact_rels_employment_count > 0} {
    append html "<td colspan=\"$contact_rels_employment_count\">Employee</td>"
}

append html "</tr>"

# Append the column headings
append html "<tr>"

foreach object_type {person organization contact_rels_employment} {
    foreach element [set ${object_type}_elements] {

	# Retrieve the attribute so we can get the widget
	ams::attribute::get -attribute_id $element -array attribute
	
	# Store the widget in an array so we can reuse it later.
	set widget($element) $attribute(widget)
	set attribute_name($element) $attribute(attribute_name)
	switch $attribute(widget) {
	    postal_address {

		# The address is made up of the parts
		# delivery_address (street), postal_code, municipality (city)
		# region, country_code (two chars), country
		foreach address_part {delivery_address postal_code municipality region country_code country} {
		    if {[exists_and_not_null ${object_type}(${element}_${address_part})]} {
			append html "<td valign=top>[_ ams.${address_part}] \[[attribute::pretty_name -attribute_id $element]::$element\]<br />([set ${object_type}(${element}_${address_part})])</td>"
		    } else {
			append html "<td valign=top>[_ ams.${address_part}] \[[attribute::pretty_name -attribute_id $element]::$element\]</td>"
		    }
		}
	    }
	    default {
		if {[exists_and_not_null ${object_type}($element)]} {
		    append html "<td valign=top>[attribute::pretty_name -attribute_id $element] \[$attribute_name($element)::$element\]<br />([set ${object_type}($element)])</td>"
		} else {
		    append html "<td valign=top>[attribute::pretty_name -attribute_id $element] \[$attribute_name($element)::$element\]</td>"
		}
	    }
	}
    }
}

append html "</tr>"
# Now it is time for the actual contents

# Get the CSV File
set csv_stream [open $file_path r]
fconfigure $csv_stream -encoding utf-8
ns_getcsv $csv_stream headers

# Get the header information with ";" as the delimitier
set headers [string trim $headers "{}"]
set headers [split $headers ";"]

# Now loop through the CSV Stream as long as there is still a line left.
while {1} {
    set n_fields [gets $csv_stream one_line]
    if {$n_fields == -1} {
	break
    }
    
    append html "<tr>"
    #Place the attributes in a list
    package require csv
    set value_list [csv::split $one_line ";"]
    for {set i 0} {$i < $n_fields} {incr i} {
	set header [lindex $headers $i]
	regsub -all { } $header {_} header
	set values($header) [lindex $value_list $i]
    }
    # And now append the values
    foreach object_type {person organization contact_rels_employment} {
	foreach element [set ${object_type}_elements] {
	    
	    # Differentiate between the widgets
	    switch $widget($element) {
		
		# Here we have to deal again with the postal_address
		postal_address {

		    foreach address_part {delivery_address postal_code municipality region country_code country} {

			# Check if a match was made
			if {[exists_and_not_null ${object_type}(${element}_${address_part})]} {
			    
			    # Column is the name of the header in the CSV
			    set column [set ${object_type}(${element}_${address_part})]
			    if {[exists_and_not_null values($column)]} {
				append html "<td>$values($column)</td>"
			    } else {
				append html "<td></td>"
			    }
			} else {
			    append html "<td></td>"
			}
		    }
		}		
		default {
		    if {[exists_and_not_null ${object_type}($element)]} {
			set column [set ${object_type}($element)]
			if {[exists_and_not_null values($column)]} {
			    append html "<td>$values($column)</td>"
			} else {
			    append html "<td></td>"
			}
		    } else {
			append html "<td></td>"
		    }
		}
	    }
	}
    }
    append html "</tr>"
}


append html "</table>"
set context "$file_name"
append html "<a href=\"[export_vars -base import-csv-4.tcl  {file_name file_path organization:array,multiple,optional person:array,multiple,optional contact_rels_employment:array,multiple,optional person_elements organization_elements contact_rels_employment_elements group_ids} ]\">OK</a>"
        
