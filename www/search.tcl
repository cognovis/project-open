ad_page_contract {
    List and manage contacts.
 
    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$
} {
    {search_id:integer,optional}
    {type ""}
    {save ""}
    {add ""}
    {next ""}
    {clear ""}
    {delete ""}
    {search ""}
    {object_type ""}
    {all_or_any ""}
    {title ""}
    {owner_id ""}
    {aggregate_attribute_id ""}
    {aggregate ""}
    {attribute_values ""}
    {attribute_option ""}
    {attribute_names ""}
    {add_column ""}
    {remove_column ""}
} -validate {
    valid_object_type -requires {object_type} {
        if { [lsearch [intranet-contacts::supported_object_types] $object_type] < 0 } {
            ad_complain "[_ intranet-contacts.You_have_specified_an_invalid_object_type]"
        }
    }
    valid_search_id -requires {search_id} {
        if { [db_0or1row condition_exists_p {}] } {
	    set valid_owner_ids [list]
	    lappend valid_owner_ids [ad_conn user_id]
	    if { [permission::permission_p -object_id [ad_conn package_id] -privilege "admin"] } {
		lappend valid_owner_ids [ad_conn package_id]
	    }
	    if { [lsearch $valid_owner_ids $owner_id] < 0 } {
		if { [contact::exists_p -party_id $owner_id] } {
		    ad_complain "[_ intranet-contacts.lt_You_do_not_have_permission_to_edit_other_peo]"
		} else {
		    ad_complain "[_ intranet-contacts.lt_You_do_not_have_permission_to_edit_this_search]"
		}
	    }
	}
    }
}

set package_url [ad_conn package_url]

if { [exists_and_not_null aggregate] } {
    ad_returnredirect "[export_vars -base ./ -url {search_id aggregate_attribute_id}]"
}

set page_title "[_ intranet-contacts.Advanced_Search]"
set context [list $page_title]

if { [exists_and_not_null clear] } {
    ad_returnredirect "search"
}

if { [exists_and_not_null delete] } {
    ad_returnredirect [export_vars -base search-action -url {search_id {action delete}}]
}

if { [exists_and_not_null search] } {
    ad_returnredirect ".?search_id=$search_id"
}


set search_exists_p 0
# set query_pretty [list]
if { [exists_and_not_null search_id] } {
    if { [contact::search::exists_p -search_id $search_id] } {
        db_1row get_search_info { }
        set search_exists_p 1
    }
}

if { $object_type eq "employee" } {
    set actual_object_type "organization"
} else {
    set actual_object_type $object_type
}

if { $search_exists_p } {

    template::multirow create ext impl type_key type_pretty key key_pretty
    
    # permissions for what attributes/extensions are visible to this
    # user are to be handled by this callback proc. The callback
    # MUST only return keys that are visible to this user

    callback contacts::extensions \
	-user_id [ad_conn user_id] \
	-multirow ext \
	-package_id [ad_conn package_id] \
	-object_type $actual_object_type
    
    set add_columns [list]
    set remove_columns [list]
    set extended_columns [contact::search::get_extensions -search_id $search_id]
    if { [lsearch $extended_columns $remove_column] >= 0 && $remove_column ne "" } {
	# remove this extension
	db_dml delete_column {}
	set extended_columns [contact::search::get_extensions -search_id $search_id]
    }
    if { [lsearch $extended_columns $add_column] <= 0 && $add_column ne ""  } {
	db_dml insert_column {}
	lappend extended_columns $add_column
    }

    # we run through the multirow here to determine wether or not the columns are allowed
    template::multirow foreach ext {
	set selected_p 0
	if { [lsearch $extended_columns "${type_key}__${key}"] >= 0 } {
	    # we want to use this column in our table
	    lappend remove_columns [list $key_pretty "${type_key}__${key}" $type_pretty]
	} else {
	    lappend add_columns [list $key_pretty "${type_key}__${key}" $type_pretty]
	}
	
    }

    # create forms to add/remove columns from the multirow
    if { [llength $add_columns] > 0 } {
	set add_columns [concat [list [list "[_ intranet-contacts.--add_column--]" "" ""]] $add_columns]
    }
    if { [llength $remove_columns] > 0 } {
	set remove_columns [concat [list [list "[_ intranet-contacts.--remove_column--]" "" ""]] $remove_columns]
    }
    
    set extended_columns_preserved $extended_columns
    
    ad_form \
	-name "add_column_form" \
	-method "GET" \
	-export {format search_id query page page_size orderby} \
	-has_submit "1" \
	-has_edit "1" \
	-form {
	    {extended_columns:text(hidden),optional}
	    {add_column:text(select_with_optgroup)
		{label ""}
		{html {onChange "document.add_column_form.submit();"}}
		{options $add_columns}
	    }
	} \
	-on_request {} \
	-on_submit {}
    
    ad_form \
	-name "remove_column_form" \
	-method "GET" \
	-export {format search_id query page page_size orderby} \
	-has_submit "1" \
	-has_edit "1" \
	-form {
	    {extended_columns:text(hidden),optional}
	    {remove_column:text(select_with_optgroup)
		{label ""}
		{html {onChange "document.remove_column_form.submit();"}}
		{options $remove_columns}
	    }
	} \
	-on_request {} \
	-on_submit {}
    

    set extended_columns $extended_columns_preserved
    template::element::set_value add_column_form extended_columns $extended_columns
    template::element::set_value remove_column_form extended_columns $extended_columns

}

if { ![exists_and_not_null owner_id] } {
    set owner_id [ad_conn user_id]
}

if { $search_exists_p } {
    set conditions [list]
    db_foreach selectqueries {} {
	set condition_name [contacts::search::condition_type -type $query_type -request pretty -var_list $query_var_list]
	if { [empty_string_p $condition_name] } {
	    set condition_name  "[_ intranet-contacts.Employees]"
	}
        lappend conditions "$condition_name <a href=\"[export_vars -base search-condition-delete -url {condition_id}]\"><img src=\"/resources/acs-subsite/Delete16.gif\" width=\"16\" height=\"16\" border=\"0\"></a>"
    }
    if { [llength $conditions] > 0 } {
	set query_pretty "<ul><li>[join $conditions {</li><li>}]</li></ul>"
    } else {
	set query_pretty ""
    }
} else {
    set query_pretty ""
}

set display_employers_p [parameter::get -boolean -parameter DisplayEmployersP -default "0"]
# FORM HEADER
set form_elements {
    {search_id:key}
    {owner_id:integer(hidden)}
}

if { [exists_and_not_null object_type] } {
    set object_type_pretty [intranet-contacts::object_type_pretty -object_type $object_type]
    append form_elements {
        {object_type:text(hidden) {value $object_type}}
        {object_type_pretty:text(inform) {label {[_ intranet-contacts.Search_for]}} {value "<strong>$object_type_pretty</strong>"} {after_html "[_ intranet-contacts.which_match]"}}
        {all_or_any:text(select),optional {label ""} {options {{[_ intranet-contacts.All] all} {[_ intranet-contacts.Any] any}}} {after_html "[_ intranet-contacts.lt_of_the_following_cond]$query_pretty"}}
    }
} else {
    set object_type_options [list]
    set object_types [intranet-contacts::supported_object_types]
    
    foreach object_type_temp $object_types {
        lappend object_type_options [list [intranet-contacts::object_type_pretty -object_type $object_type_temp] $object_type_temp]
    }
    
    if { $display_employers_p } {
	    lappend object_type_options [list "[_ intranet-contacts.Employee]" "employee"]
    }
    
    append form_elements {
        {object_type:text(select) {label {\#intranet-contacts.Search_for\#}} {options $object_type_options} {html {onChange "javascript:acs_FormRefresh('advanced_search')"}}}
    }
}



# The employee search only works without other attribute so 
# we are going to remove the option "Employee" where is already
# a condition_name and we are going to remove the attributes
# where the condition_name equals employee
set employee_p 0
if { [exists_and_not_null object_type] } {

    # QUERY TYPE
    set type_options_temp [contacts::search::condition_types]
    set type_options ""
    
    # We are going to add one extra element to show all employees
    # and its organization
    foreach type_temp $type_options_temp {
        if {[lindex $type_temp 1] eq "group" && $object_type ne "person"} {
            # only persons can have groups
        } elseif {[lindex $type_temp 1] eq "subtype" && $object_type eq "person"} {
            # persons cannot have subtypes
        } else {
            lappend type_options $type_temp
        }
    }
    
    if { $object_type eq "person" && ![exists_and_not_null condition_name] } {
	        lappend type_options [list "[_ intranet-contacts.Employees]" employees]
	}
    
    if { [exists_and_not_null condition_name] && [string equal $condition_name [_ intranet-contacts.Employees]] } {
	set employee_p 1
    }

    if { $search_exists_p } {
	# the search already exists so we put the option of not selecting
        # a new condition type, otherwise all form manipulations make
        # the assumption that a new type was selected
	set type_options [concat [list [list "- - - -" ""]] $type_options]
    }
    if { !$employee_p } {
	# Show the attribute options of the search
	append form_elements {
	    {type:text(select),optional {label {}} {options $type_options} {html {onChange "javascript:acs_FormRefresh('advanced_search')"}}}
	}
    }
}

#get condition types widgets
set form_elements [concat \
		       $form_elements \
               [contacts::search::condition_type -type $type -request ad_form_widgets -form_name advanced_search -object_type $actual_object_type]
               ]
if { !$employee_p } {
    # Show the Ok button
    lappend form_elements  [list next:text(submit) [list label [_ acs-kernel.common_OK]] [list value "ok"]]
}


if { $search_exists_p } {

    set results_count [contact::search::results_count -search_id $search_id] 

    append form_elements {
        {title:text(text),optional {label "<br><br>[_ intranet-contacts.save_this_search_]"} {html {size 40 maxlength 255}}}
        {save:text(submit) {label "[_ intranet-contacts.Save]"} {value "save"}}
        {search:text(submit) {label "[_ intranet-contacts.Search]"} {value "search"}}
        {clear:text(submit) {label "[_ intranet-contacts.Clear]"} {value "clear"}}
    }

    
    if { $display_employers_p } {

	append form_elements {
	    {delete:text(submit) {label "[_ intranet-contacts.Delete]"} {value "delete"} \
		 {after_html "<br>[_ intranet-contacts.Aggregate_by]:<br>"}
	    }
	}
	append form_elements [contacts::search::condition_type::attribute \
				  -request ad_form_widgets \
				  -prefix "aggregate_" \
				  -without_arrow_p "t" \
				  -only_multiple_p "t" \
				  -package_id [ad_conn package_id]]

	append form_elements {
	    {aggregate:text(submit) {label "[_ intranet-contacts.Aggregate]"} {value "aggregate"} {after_html "&nbsp;&nbsp;<span style=\"font-size: smaller;\">[_ intranet-contacts.Results]</span> <a href=\"[export_vars -base ./ -url {search_id}]\">$results_count</a>"}}
	}
    } else {
	append form_elements {
	    {delete:text(submit) {label "[_ intranet-contacts.Delete]"} {value "delete"} \
		 {after_html "&nbsp;&nbsp;<span style=\"font-size: smaller;\">[_ intranet-contacts.Results]</span> <a href=\"[export_vars -base ./ -url {search_id}]\">$results_count</a>"}
	    }
	    aggregate:text(hidden),optional
	}
    }
}

ad_form -name "advanced_search" -method "GET" -form $form_elements \
    -on_request {
    } -edit_request {
    } -on_refresh {
    } -on_submit {
        if { [contact::search::exists_p -search_id $search_id] } {
            contact::search::update -search_id $search_id -title $title -owner_id $owner_id -all_or_any $all_or_any
        }

	if { ![string equal $type "employees"] } {
	    set form_var_list [contacts::search::condition_type \
				   -type $type \
				   -request form_var_list \
				   -form_name advanced_search]
	} else {
	    set form_var_list "employees"
	}

        if { $form_var_list != "" } {
            if { [string is false [contact::search::exists_p -search_id $search_id]] } {
                set search_id [contact::search::new -search_id $search_id -title $title -owner_id $owner_id -all_or_any $all_or_any -object_type $object_type]
            }

            contact::search::condition::new -search_id $search_id -type $type -var_list $form_var_list

        }
    } -after_submit {
        if { $form_var_list != "" || [exists_and_not_null save] } {
            set export_list [list search_id]
            if { ![contact::search::exists_p -search_id $search_id] } {
                lappend export_list object_type all_or_any
            } else {
		contact::search::flush -search_id $search_id
	    }
            ad_returnredirect [export_vars -base "search" -url [list $export_list]]
            ad_script_abort
	}
    }


