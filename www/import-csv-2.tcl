ad_page_contract {
    page to import a csv file to the system (contacts)

    @author Nils Lohse (nils.lohse@cognovis.de)
    @creation-date 21 Nov 2006
} {
    {return_url ""}
    upload_file.tmpfile:tmpfile
    upload_file
    group_ids:integer,multiple,optional
} -properties {
    context:onevalue
    instructions:onevalue
}

package require csv
# Get the file name and file path of the uploaded csv file
set file_name $upload_file
set file_path ${upload_file.tmpfile}

set user_id [ad_conn user_id]
set package_id [ad_conn package_id]
set package_key "contacts"

set context "[_ intranet-contacts.import_csv_2_context]"

# Initial lists for list ids
set person_elements [list]
set organization_elements [list]
set contact_rels_employment_elements [list]

if {![info exists group_ids]} {
    set group_ids [list]
}

# Get the CSV File
set new_file_path [ns_tmpnam] 
ns_cp $file_path $new_file_path
set csv_stream [open $file_path r]
fconfigure $csv_stream -encoding utf-8
ns_getcsv $csv_stream headers

# Get the header information with ";" as the delimitier
set headers [string trim $headers "{}"]
set headers [split $headers ";"]

set header_options [list]
foreach header $headers {
    regsub -all { } $header {_} header
    lappend header_options [list $header $header]
}

# We needed to copy the file as it is deleted after the page runs
set file_path $new_file_path

# Get the list of attributes
set default_group [contacts::default_group]
if {[lsearch $group_ids $default_group] == -1} {
    set group_ids [concat $default_group $group_ids]
}

foreach group_id $group_ids {
    # Adding the list_name to get the elements in the form
    set l_name [list ${package_id}__${group_id}]
    
    foreach object_type {person organization} {
	# Retrieve the list ids
	set list_id [ams::list::get_list_id -package_key $package_key -object_type $object_type -list_name $l_name]
	if {![empty_string_p $list_id]} {
	    lappend list_ids $list_id
	}
    }
}

# Append the list id for the employee relationship
set list_id [ams::list::get_list_id -package_key $package_key -object_type "contact_rels_employment" -list_name $package_id]
if {![empty_string_p $list_id]} {
    lappend list_ids $list_id
}

# Retrieve the elements
foreach list_id $list_ids {
    set object_type [db_string object_type "select object_type from ams_lists where list_id = $list_id"]
    set element_counter 0
    
    foreach element [ams::elements -list_ids $list_id] {
	set attribute_id [lindex $element 0]
	if {[lsearch [set ${object_type}_elements] $attribute_id] <0 } {
	    # Append the attribute_id to the list of attributes
	    lappend ${object_type}_elements $attribute_id
	    
	    set required_p      [lindex $element 1]
	    set attribute_name  [lindex $element 3]
	    set widget          [lindex $element 5]
	    set pretty_name     [lang::util::localize [lindex $element 4]]
	    
	    # If the pretty_name matches on of the headers, then use it
	    set match [lsearch -regexp $headers (?i)^${pretty_name}\$]
	    if {$match > -1} {
		set attribute_name [lindex $headers $match]
	    }
	    
	    # Make sure you have a header for required elements
	    if {$required_p} {
		set opt_string ""
	    } else {
		set opt_string ",optional"
	    }
	    
	    switch $widget {
		postal_address {
		    # Postal address is made up of many values
		    set form_element [list ${object_type}.${attribute_id}_delivery_address:text(multiselect)$opt_string \
					  [list label "[_ ams.delivery_address] ($pretty_name)"] \
					  [list options "$header_options"]]
		    # Append the secion
		    if { $element_counter eq 0} {
			lappend form_element [list section $object_type]
		    }
		    lappend elements $form_element
		    
		    # postal code
		    set form_element [list ${object_type}.${attribute_id}_postal_code:text(multiselect)$opt_string \
					  [list label "[_ ams.postal_code] ($pretty_name)"] \
					  [list options "$header_options"]]
		    lappend elements $form_element
		    
		    # municipality
		    set form_element [list ${object_type}.${attribute_id}_municipality:text(multiselect)$opt_string \
					  [list label "[_ ams.municipality] ($pretty_name)"] \
					  [list options "$header_options"]]
		    lappend elements $form_element
		    
		    # region
		    set form_element [list ${object_type}.${attribute_id}_region:text(multiselect)$opt_string \
					  [list label "[_ ams.region] ($pretty_name)"] \
					  [list options "$header_options"]]
		    lappend elements $form_element
		    
		    # country_code
		    set form_element [list ${object_type}.${attribute_id}_country_code:text(multiselect)$opt_string \
					  [list label "[_ ams.country_code] ($pretty_name)"] \
					  [list options "$header_options"]]
		    lappend elements $form_element
		    
		    # country
		    set form_element [list ${object_type}.${attribute_id}_country:text(multiselect)$opt_string \
					  [list label "[_ ams.country] ($pretty_name)"] \
					  [list options "$header_options"]]
		    lappend elements $form_element
		    
		}		
		default {
		    set form_element [list ${object_type}.${attribute_id}:text(multiselect)$opt_string \
					  [list label "$pretty_name"] \
					  [list options "$header_options"] \
					  [list value "$attribute_name"]]
		    # Append the secion
		    if { $element_counter eq 0} {
			lappend form_element [list section $object_type]
		    }
		    lappend elements $form_element
		}
	    }
	    incr element_counter
	}
    }
}

#ad_return_error test $elements

ad_form -name csv-import -action import-csv-3 -html { enctype multipart/form-data } -export { return_url file_name file_path person_elements organization_elements contact_rels_employment_elements group_ids} -form $elements


set instructions "[_ intranet-contacts.lt_csv_import_instructions]"

ad_return_template
