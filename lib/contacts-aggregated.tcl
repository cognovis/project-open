set required_param_list [list attr_id search_id]
set optional_param_list [list base_url extend_id]
set optional_unset_list [list]

foreach required_param $required_param_list {
    if { ![info exist $required_param] } {
	ad_return_complaint 1 "Parameter $required_param is required"
    }
}

foreach optional_param $optional_param_list {
    if { ![exists_and_not_null ${optional_param}] } {
	set $optional_param ""
    }
}

foreach unset_param $optional_unset_list {
    if { ![exists_and_not_null ${optional_param}] } {
	unset $unset_param
    }
}

# Get the search message
set message [contact::search_pretty -search_id $search_id]

# You can aggregate for attributes that have multiple choices
# or by relationship or country. Each one of this situations
# has it's own queries to make the multirow and to get the results
switch '$attr_id' {
    '-1' {
	# Search for the country in home_address 
	# or company_addres
	set attr_name "[_ intranet-contacts.Country]"
	set query_name get_countries_options
	set result_query get_countries_results
	set extend_result_query get_countries_extend_results
	set attribute_p 0
    } 
    '-2' {
	# Search for Relationship's
	set attr_name "[_ intranet-contacts.Relationship]"
	set query_name get_relationship_options
	set result_query get_relationship_results
	set extend_result_query get_relationship_extend_results
	set attribute_p 0
    }
    default {
	# Get the attribute name and the options for that attribute
	set attr_name [attribute::pretty_name -attribute_id $attr_id]
	set query_name get_attribute_options
	set result_query get_results
	set extend_result_query get_extend_results
	set attribute_p 1
    }
}


# Get the search_clasue used in the advanced search
set search_clause [contact::search_clause -and \
		       -search_id $search_id \
		       -query "" \
		       -party_id "parties.party_id" \
		       -revision_id "revision_id"]


# If we are extending the result list then 
# we add the element dynamically to the list

set elements [list \
		  option [list \
			      label "<b>$attr_name</b>"] \
		  result [list \
			      display_template {
				  @contacts.result@
			      }]]

set extend_list [list result]


set saved_extend_ids [db_list get_saved_extend_ids { }]
foreach extend $extend_id {
    lappend saved_extend_ids $extend
}

set extend_id $saved_extend_ids

if { [exists_and_not_null extend_id] } {
    foreach extend $extend_id {
	set extend_info [contact::extend::option_info -extend_id $extend]
	set extend_var_name    [lindex [lindex $extend_info 0] 0]
	set extend_pretty_name [lindex [lindex $extend_info 0] 1]
	lappend elements $extend_var_name [list label "<b>$extend_pretty_name</b>"]
	# For the db_multirow extend variables
	lappend extend_list $extend_var_name
    }
}

# We create the list
template::list::create  \
    -name "contacts" \
    -multirow contacts \
    -row_pretty_plural "" \
    -actions "" \
    -bulk_actions "" \
    -elements $elements

db_multirow -extend $extend_list contacts $query_name " " {
    # We get the value_id here and not in the options query since
    # the value_id is only present when one attribute is associated
    # to one option, and we want to see every option.
    set option_string [lang::util::localize $option]
    if { [string equal "Contact Rel " [string range $option_string 0 11]] } {
	# This is for relationships aggregation
	set option [string range $option_string 12 [string length $option_string]]
    }
    if { $attribute_p } {
	# No country or relationship we need the value of the attribute
	# To get the result
	set value_id [db_string get_value_id { } -default 0]
    }
    
    # Get the result for each specific situation
    set result [db_string $result_query " " -default 0]

    # Get the extend_var_name value for the extend attribute
    if {[exists_and_not_null extend_id] } {

	foreach extend $extend_id {
	    set extend_info [contact::extend::option_info -extend_id $extend]
	    set extend_var_name    [lindex [lindex $extend_info 0] 0]
	    set extend_subquery    [lindex [lindex $extend_info 0] 2]
	    if { [catch {  set $extend_var_name [db_string $extend_result_query " " -default 0]
		set value [db_string $extend_result_query " " -default 0] } errMsg] } {
		# We got an error so we are going to return to the user
		set title "[_ intranet-contacts.extend_error_msg]"
		set error_pos [string first "ERROR: " $errMsg]
		set sql_pos [string first "SQL: " $errMsg]
		set error [string range $errMsg [expr $error_pos + 7] [expr $sql_pos - 1]]
		set sql [string range $errMsg [expr $sql_pos + 5] [string length $errMsg]]
		ad_return_error $title "<b>[_ intranet-contacts.Error]:</b><br> $error <br><br><b>SQL:</b><br>$sql<br>"
		ad_script_abort
	    }
	    if { [empty_string_p $value] } {
		set $extend_var_name "0.00"
	    }
	}
    }
}



# This is for the display of the forms
# for the aggregate and extend options
set select_options [list]

foreach option [contacts::attribute::options_attribute] {
    lappend select_options [list [lang::util::localize [lindex $option 0]] [lindex $option 1]]
}

ad_form -name aggregate -has_submit "1" -form {
    {search_id:integer(hidden)
	{value $search_id}
    }
    {aggregate_extend_id:text(hidden)
	{value $extend_id}
    }
    {aggregate_attribute_id:integer(select)
	{label "[_ intranet-contacts.Aggregate_by]" }
	{value $attr_id}
	{options $select_options}
	{html { onChange document.aggregate.submit();}}
    }
}

# We get only the options that are mapped to the search_id
# and that have the aggregate_p filed set to "t"
set extend_options [db_list_of_lists get_extend_options { }]

if { [string equal [llength $extend_options] 0] } {
    set extend_id ""
}

set extend_options [linsert $extend_options 0 [list "- - - - - - " ""]]

ad_form -name extend -has_submit "1" -form {
    {search_id:integer(hidden)
	{value $search_id}
    }
    {aggregate_attribute_id:integer(hidden)
	{value $attr_id}
    }
    {aggregate_extend_id:text(multiselect),optional
	{label "<div align=top>[_ intranet-contacts.Extend_result_list_by]:</div>" }
	{options $extend_options}
	{html { onChange document.extend.submit();}}
	{value $extend_id}
    }
}


ad_form -has_submit 1 -name save -form {
    {search_id:integer(hidden)
	{value $search_id}
    }
    {aggregate_attribute_id:integer(hidden)
	{value $attr_id}
    }
    {extend_id:text(hidden)
	{value $extend_id}
    }
} -on_submit {
    foreach extend $extend_id {
	set already_p [db_string check { } -default 0]
	if { !$already_p } {
	    db_dml insert_extend { }
	}
    }
    db_dml update_search { }
} -after_submit {
    ad_returnredirect "?search_id=$search_id&aggregate_attribute_id=$aggregate_attribute_id"
}
