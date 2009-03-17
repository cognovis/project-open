set required_param_list [list]
set optional_param_list [list base_url extend_p extend_values attr_val_name category_id]
set default_param_list  [list orderby format query page page_size package_id search_id group_id]

# default values for default params
set _orderby "first_names,asc"
set _format "normal"
set _page_size "25"
set admin_p 0


if { [string is false [exists_and_not_null package_id]] } {
    set package_id [ad_conn package_id]
}

foreach required_param $required_param_list {
    set $required_param [ns_queryget $default_param]
    if { ![exists_and_not_null required_param] } {
	return -code error "$required_param is a required parameter."
    }
}

foreach optional_param $optional_param_list {
    if { ![exists_and_not_null ${optional_param}] } {
	set $optional_param ""
    }
}

foreach default_param $default_param_list {
    set $default_param [ns_queryget $default_param]
    if { ![exists_and_not_null ${default_param}] && [exists_and_not_null "_${default_param}"] } {
	set $default_param [set _${default_param}]
    }
}


# if a double colon is in the query then the paginator messes up because it evals
# the page string and attempts to run it as a proc, so we remove all double colons
# here.
while { [regsub -all {::} $query {:} query] } {}


# see if the person is attemping to add
# or remove a column
set extended_columns [ns_queryget extended_columns]
set add_column       [ns_queryget add_column]
set remove_column    [ns_queryget remove_column]
if { $extended_columns ne "" && $remove_column ne "" } {
    set lindex_id [lsearch -exact $extended_columns $remove_column]
    if { $lindex_id >= 0 } {
	set extended_columns [lreplace $extended_columns $lindex_id $lindex_id]
    }
}
if { $add_column ne "" } {
    lappend extended_columns $add_column
}

set add_column ""
set remove_column ""


# Check if this is a report
set report_p [ns_queryget report_p]
if { [string is true $report_p] && $report_p ne "" } {
    set report_csv_url    [export_vars -base $base_url -url {{format csv} search_id query page page_size extended_columns orderby {report_p 1}}]
    set contacts_mode_url [export_vars -base $base_url -url {format search_id query page page_size extended_columns orderby {report_p 0}}]
} else {
    set report_p 0
    set report_mode_url [export_vars -base $base_url -url {format search_id query page page_size extended_columns orderby {report_p 1}}]
}




# This is for showing the employee_id and employeer relationship
set condition_type_list [db_list get_condition_types {}] 


# If we do not have a search_id, limit the list to only users in the default group.
if {[exists_and_not_null search_id]} {
    # Also we can extend this search.
    # Is to allow extend the list by any extend_options defined in contact_extend_options
    set extend_options [contact::extend::get_options \
				    -ignore_extends $extend_values \
				    -search_id $search_id -aggregated_p "f"]
    if { [llength $extend_options] == 0 } {
	set hide_form_p 1
    }

    set available_options [concat \
			       [list [list "- - - - - - - -" ""]] \
			       $extend_options \
			       ]

    ad_form -name extend -form {
	{extend_option:text(select),optional
	    {label "[_ intranet-contacts.Available_Options]" }
	    {options {$available_options}}
	}
	{search_id:text(hidden)
	    {value "$search_id"}
	}
	{extend_values:text(hidden)
	    {value "$extend_values"}
	}
    } -on_submit {
	# We clear the list when no value is submited, otherwise
	# we acumulate the extend values.
	if { [empty_string_p $extend_option] } {
	    set extend_values [list]
	} else {
	    lappend extend_values [list $extend_option] 
	}
	ad_returnredirect [export_vars -base "?" {search_id extend_values extended_columns}]
    }
}


set group_by_group_id ""
if { ![exists_and_not_null group_id] } {
    set where_group_id " = [contacts::default_group]"
} else {
    if {[llength $group_id] > 1} {
	set where_group_id " IN ('[join $group_id "','"]')"
	set group_by_group_id "group by parties.party_id , parties.email"
    } else {
	set where_group_id " = :group_id"
    }
}


set last_modified_join ""
set last_modified_clause ""
set last_modified_rows ""

set return_url "[ad_conn url]?[ad_conn query]"

set object_type [contact::search::object_type -search_id $search_id -default {person}]

# Get the table information
set clauses [intranet-contacts::table_and_join_clauses -object_type $object_type -category_id $category_id]
set contact_tables [lindex $clauses 0]
set join_clauses [lindex $clauses 1]

# Deal with elements and sort orders
set elements [list]


append name_label_trail " &nbsp;&nbsp; [_ intranet-contacts.Show]: "

set valid_page_sizes [list 25 50 100 500]
if { ![exists_and_not_null page_size] || [lsearch $valid_page_sizes $page_size] < 0 } {
    set page_size [parameter::get -parameter "DefaultPageSize" -default "50"]
}
foreach page_s $valid_page_sizes {
    if { $page_size == $page_s } {
        lappend page_size_list $page_s
    } else {
        lappend page_size_list "<a href=\"[export_vars -base $base_url -url {format search_id query page orderby extended_columns {page_size $page_s}}]\">$page_s</a>"
    }
}
append name_label_trail [join $page_size_list " | "]


# Should we allow CSV 
if { [string is true [parameter::get -parameter "DisableCSV" -default "0"]] || ![acs_user::site_wide_admin_p] } {
    set format normal
} else {
    append name_label_trail "&nbsp;&nbsp;&nbsp;[_ intranet-contacts.Get]: <a href=\"[export_vars -base $base_url -url {{format csv} search_id query page orderby page_size extended_columns}]\">[_ intranet-contacts.CSV]</a>"
}

set company_url  [export_vars -base $base_url -url {format search_id query page page_size extended_columns {orderby {company,asc}}}]
set last_modified_url [export_vars -base $base_url -url {format search_id query page page_size extended_columns {orderby {last_modified,desc}}}]

template::multirow create bulk_acts pretty link detailed

# fraber 090317: Disabled Add_Relationship - doesn't work
# template::multirow append bulk_acts "[_ intranet-contacts.Add_Relationship]" "${base_url}relationship-bulk-add" "[_ intranet-contacts.lt_Add_relationship_to_sel]"

if { [permission::permission_p -object_id $package_id -privilege "admin"] || [acs_user::site_wide_admin_p]  } {
    set admin_p 1

# Malte & fraber 090306
#    template::multirow append bulk_acts "[_ intranet-contacts.Bulk_Update]" "${base_url}bulk-update" "[_ intranet-contacts.lt_Bulk_update_the_seclected_C]"

}
callback contacts::bulk_actions -multirow "bulk_acts"

# Deal with the display in the list
switch $object_type {
    person {
        template::multirow append bulk_acts "[_ intranet-contacts.Mail_Merge]" "${base_url}message" "[_ intranet-contacts.lt_E-mail_or_Mail_the_se]"
        template::multirow append bulk_acts "[_ intranet-contacts.Add_to_Group]" "${base_url}group-parties-add" "[_ intranet-contacts.Add_to_group]"
        template::multirow append bulk_acts "[_ intranet-contacts.Remove_From_Group]" "${base_url}group-parties-remove" "[_ intranet-contacts.lt_Remove_from_this_Grou]"
        set first_names_url   [export_vars -base $base_url -url {format search_id query page page_size extended_columns {orderby {first_names,asc}}}]
        set last_name_url     [export_vars -base $base_url -url {format search_id query page page_size extended_columns {orderby {last_name,asc}}}]
        if {$orderby eq "" || $orderby eq "first_names,asc"} {
            set name_label "[_ intranet-contacts.Sort_by] [_ intranet-contacts.First_Names] | <a href=\"${last_name_url}\">[_ intranet-contacts.Last_Name]</a> | <a href=\"${last_modified_url}\">[_ intranet-contacts.Last_Modified]</a>"            
        } else {
            set orderby "last_name,asc"
            set name_label "[_ intranet-contacts.Sort_by] <a href=\"${first_names_url}\">[_ intranet-contacts.First_Names]</a> | [_ intranet-contacts.Last_Name] | <a href=\"${last_modified_url}\">[_ intranet-contacts.Last_Modified]</a>"
        }
        lappend elements contact [list \
        			      label {<span style=\"float: right; font-weight: normal; font-size: smaller\">$name_label $name_label_trail</span>} \
        			      display_template { 
        				   <a href="@contacts.contact_url@">@contacts.name;noquote@</a>@contacts.orga_info;noquote@
         				   <if @contacts.email@ not nil or @contacts.url@ not nil>
        				       <span class="contact-attributes">
        				       <if @contacts.email@ not nil>
                                                   <a href="@contacts.message_url@">@contacts.email@</a>
        		                       </if>
        		                       <if @contacts.url@ not nil>
                                                    <if @contacts.email@ not nil>
                                                         ,
                                                    </if>
                                                    <a href="@contacts.url@">@contacts.url@</a>
         		                       </if>
        				       </span>
                                	   </if>
        			      }]
        			      
    }
    im_company { 
	    template::multirow append bulk_acts "[_ intranet-contacts.Add_to_List]" "${base_url}list-parties-add" "[_ intranet-contacts.Add_to_List]"
        template::multirow append bulk_acts "[_ intranet-contacts.Remove_from_List]" "${base_url}list-parties-remove" "[_ intranet-contacts.Remove_from_List]"
	    set orderby "company,asc"
	    set name_label "[_ intranet-contacts.Sort_by] [_ intranet-contacts.Company]| <a href=\"${last_modified_url}\">[_ intranet-contacts.Last_Modified]</a>"
	    lappend elements contact [list \
        			      label {<span style=\"float: right; font-weight: normal; font-size: smaller\">$name_label $name_label_trail</span>} \
        			      display_template { 
					  <a href="@contacts.contact_url@">@contacts.company_name;noquote@</a>
        				   <span class="contact-editlink">
					  \[<a href="${base_url}contact-add?party_id=@contacts.object_id@">[_ intranet-contacts.Edit]</a>\]
					  </span>
        			      }]
    }
    im_office { 
	    template::multirow append bulk_acts "[_ intranet-contacts.Add_to_List]" "${base_url}list-parties-add" "[_ intranet-contacts.Add_to_List]"
        template::multirow append bulk_acts "[_ intranet-contacts.Remove_from_List]" "${base_url}list-parties-remove" "[_ intranet-contacts.Remove_from_List]"
	    set orderby "office,asc"
	    set name_label "[_ intranet-contacts.Sort_by] [_ intranet-contacts.Office]| <a href=\"${last_modified_url}\">[_ intranet-contacts.Last_Modified]</a>"
	    lappend elements contact [list \
        			      label {<span style=\"float: right; font-weight: normal; font-size: smaller\">$name_label $name_label_trail</span>} \
        			      display_template { 
					  <a href="@contacts.contact_url@">@contacts.office_name;noquote@</a>
        				   <span class="contact-editlink">
					  \[<a href="${base_url}contact-add?party_id=@contacts.object_id@">[_ intranet-contacts.Edit]</a>\]
					  </span>
        			      }]
    }
}

set bulk_actions [list]
template::multirow foreach bulk_acts {
    lappend bulk_actions $pretty $link $detailed
}

lappend elements contact_id [list display_col object_id]
lappend elements last_modified [list display_col last_modified label [_ intranet-contacts.Last_Modified]]
lappend elements name [list display_col name label [_ intranet-contacts.Name]]
lappend elements edit_link [list label "" \
                                display_template {<span class="contact-editlink">
                                    \[<a href="${base_url}contact-add?party_id=@contacts.object_id@">[_ intranet-contacts.Edit]</a>\]
	                            </span>}]


# Deal with the search
set page_query_name "contacts_pagination"
set multirow_query_name "contacts_select"
set search_clause 	[contact::search_clause -and -search_id $search_id -query $query -party_id acs_objects.object_id -limit_type_p "0"]

if { $format == "csv" } {
    set row_list [list contact_id {} name {}]
    if { $object_type ne "organization" } {
	lappend row_list first_names {} last_name {}
    }
    lappend row_list email {}
    
} else {

    set row_list [list \
		  checkbox {
		      html {style {width: 30px; text-align: center;}}
		  } \
		      contact {} \
		 ] 
}

set row_list [concat $row_list $last_modified_rows]
lappend row_list "edit_link" [list]
if { [exists_and_not_null search_id] } {
    # We get all the default values for that are mapped to this search_id
    set default_values [db_list_of_lists get_default_extends { }]
    set extend_values [concat $default_values $extend_values]
}

# For each extend value we add the element to the list and to the query
# The extend values are extended table information, so columns
set extend_query ""
foreach value $extend_values {
    set extend_info [lindex [contact::extend::option_info -extend_id $value] 0]
    set name        [lindex $extend_info 0]
    set pretty_name [lindex $extend_info 1]
    set sub_query   [lindex $extend_info 2]
    lappend elements $name [list label "$pretty_name" display_template "@contacts.${name};noquote@"]
    lappend row_list $name [list]
    append extend_query "( $sub_query ) as $name,"
}

set date_format [lc_get formbuilder_date_format]


set actions [list]
if { $admin_p && [exists_and_not_null search_id] } {
    set actions [list "[_ intranet-contacts.Set_default_extend]" "admin/ext-search-options?search_id=$search_id" "[_ intranet-contacts.Set_default_extend]" ]
}


template::multirow create ext impl table_name type_pretty key key_pretty

# permissions for what attributes/extensions are visible to this
# user are to be handled by this callback proc. The callback
# MUST only return keys that are visible to this user

callback contacts::extensions \
    -user_id [ad_conn user_id] \
    -multirow ext \
    -package_id [ad_conn package_id] \
    -object_type $object_type


set add_columns [list]
set remove_columns [list]
set db_extend_columns [list]
if { $search_id ne "" } {
    # now we get the extensions for this specific search
    set db_extend_columns [contact::search::get_extensions -search_id $search_id]
}
set combined_extended_columns [lsort -unique [concat $db_extend_columns $extended_columns]]

# we run through the multirow here to determine wether or not the columns are allowed
set report_elements [list]
set key_selects [list]
template::multirow foreach ext {
    set selected_p 0
    set immutable_p 0
    if { [lsearch $combined_extended_columns "${table_name}__${key}"] >= 0 } {
        # we want to use this column in our table
        set selected_p 1
        if { [lsearch $db_extend_columns "${table_name}__${key}"] >= 0 } {
            set immutable_p 1
        }
        # we add the column to the template::list
        set element [list "${table_name}__${key}" [list \
            label $key_pretty \
            display_col "${table_name}__${key}" \
            display_template "@contacts.${table_name}__${key};noquote@"
            ]]
        set elements [concat $elements $element]
	    lappend report_elements "${table_name}__${key}" [list label $key_pretty display_col "${table_name}__${key}" display_template "@report.${table_name}__${key};noquote@"]
	    lappend key_selects "im_name_from_id(${table_name}.$key) as ${table_name}__${key}"
	    set row_list [concat $row_list [list "${table_name}__${key}" {}]]
    }
    if { [string is true $selected_p] && [string is false $immutable_p] } {
	    lappend remove_columns [list $key_pretty "${table_name}__${key}" $type_pretty]
    } elseif { [string is false $selected_p] } {
	    lappend add_columns [list $key_pretty "${table_name}__${key}" $type_pretty]
    }
}

if {[llength $key_selects] > 0} {
    set select_string ", [join $key_selects ","]"
} else {
    set select_string ""
}

if { [string is false $report_p] } {


    template::list::create \
	    -html {width 100%} \
	    -name "contacts" \
	    -multirow "contacts" \
	    -row_pretty_plural "[_ intranet-contacts.contacts]" \
	    -checkbox_name checkbox \
	    -selected_format ${format} \
	    -key object_id \
	    -page_size $page_size \
	    -page_flush_p t \
	-page_query_name $page_query_name \
	-actions $actions \
	-bulk_actions $bulk_actions \
	-bulk_action_method post \
	-bulk_action_export_vars { return_url } \
	-elements $elements \
	-filters {
	    search_id {}
	    page_size {}
	    extend_values {}
	    attribute_values {}
	    query {}
	    extended_columns {}
	} -orderby {
	    first_names {
		    label "[_ intranet-contacts.First_Name]"
		    orderby_asc  "lower(persons.first_names) asc, lower(persons.last_name) asc"
		    orderby_desc "lower(persons.first_names) desc, lower(persons.last_name) desc"
	    }
	    last_name {
		    label "[_ intranet-contacts.Last_Name]"
		    orderby_asc  "lower(persons.last_name) asc, lower(persons.first_names) asc"
		    orderby_desc "lower(persons.last_name) desc, lower(persons.first_names) desc"
	    }
	    company {
		    label "[_ intranet-contacts.Company]"
		    orderby_asc  "lower(im_companies.company_name) asc"
		    orderby_desc  "lower(im_companies.company_name) desc"
	    }
	    office {
		    label "[_ intranet-contacts.Office]"
		    orderby_asc  "lower(im_offices.office_name) asc"
		    orderby_desc  "lower(im_offices.office_name) desc"
	    }
	    last_modified {
		    label "[_ intranet-contacts.Last_Modified]"
		    orderby_asc "acs_objects.last_modified asc"
		    orderby_desc "acs_objects.last_modified desc"
	    }
	    default_value first_names,asc
	} -formats {
	    normal {
		label "[_ intranet-contacts.Table]"
		layout table
		page_size $page_size
		row {
		    $row_list
		}
	    }
	    csv {
		label "[_ intranet-contacts.CSV]"
		output csv
		page_size 64000
		row {
		    $row_list
		}
	    }
	}

    db_multirow -extend [list contact_url message_url name orga_info] -unclobber contacts $multirow_query_name {} {
	    set contact_url [contact::url -party_id $object_id]
	    set message_url [export_vars -base "${contact_url}message" {{message_type "email"}}]
	    set name "[contact::name -party_id $object_id]"
	
	    set display_employers_p [parameter::get \
				     -parameter DisplayEmployersP \
				     -package_id $package_id \
				     -default "0"]
	
        set orga_info {}
	    if {$display_employers_p && $object_type eq "person"} {
	        # We want to display the names of the organization behind the employees name
	        set companies [contact::util::get_employers -employee_id $object_id]
	        if {[llength $companies] > 0} {
		
		        foreach company $companies {
		            set company_url [contact::url -party_id [lindex $company 0]]
		            set company_name [lindex $company 1]
		            lappend orga_info "<a href=\"$company_url\">$company_name</a>"
		        }
		
		        if {![empty_string_p $orga_info]} {
		            set orga_info " - ([join $orga_info ", "])"
		        }
	        }
	    }
    }
    

    if { [exists_and_not_null query] && [template::multirow size contacts] == 1 } {
	    # Redirecting the user directly to the one resulted contact
	    ad_returnredirect [contact::url -party_id [template::multirow get contacts 1 object_id]]
	    ad_script_abort
    }

    # extend the multirow
    template::list::get_reference -name contacts
    if { [empty_string_p $list_properties(page_size)] || $list_properties(page_size) == 0 } {
	# we give an alias that won't likely be used in the contacts::multirow extend callbacks
	# because those callbacks may have references to a parties table and we don't want 
	# postgresql to think that this query belongs to that table.
	set select_query "select p[ad_conn user_id].party_id from parties p[ad_conn user_id]"
    } else {
	set select_query [template::list::page_get_ids -name "contacts"]
    }

    if { $format == "csv" } {
	set extend_format "text"
    } else {
	set extend_format "html"
    }

    contacts::multirow \
	-extend $combined_extended_columns \
	-multirow contacts \
	-select_query $select_query \
	-format $extend_format
 
    list::write_output -name contacts

} else {

    ##
    ## This is a report
    ##

    if { [llength $combined_extended_columns] == "0"} {
	ad_returnredirect -message [_ intranet-contacts.lt_Aggregated_reports_require_added_columns] $contacts_mode_url
	ad_script_abort
    }


    set party_ids [list]
    db_multirow contacts report_contacts_select {} {
	lappend party_ids $party_id
    }

    if { [llength $party_ids] < 10000 } {
	# postgresql cannot deal with lists larger than 10000
	set select_query [template::util::tcl_to_sql_list $party_ids]
    } else {
	set select_query "select p[ad_conn user_id].party_id from parties p[ad_conn user_id]"
    }

    if { $format == "csv" } {
	set extend_format "text"
    } else {
	set extend_format "html"
    }

    contacts::multirow \
	-extend $combined_extended_columns \
	-multirow contacts \
	-select_query $select_query \
	-format $extend_format

    template::list::create \
	-html {width 100%} \
	-name "report" \
	-multirow "report" \
	-selected_format ${format} \
	-elements [concat $report_elements [list quantity [list label [_ intranet-contacts.Quantity]]]] \
	-formats {
	    normal {
		label "[_ intranet-contacts.Table]"
		layout table
	    }
	    csv {
		label "[_ intranet-contacts.CSV]"
		output csv
	    }
	}
    


    set command [list template::multirow create report]
    foreach {element details} $report_elements {
	lappend command $element
    }
    lappend command quantity
    eval $command

    
    set keys [list]
    template::multirow foreach contacts {
	set key [list]
	foreach {element details} $report_elements {
	    if { $element ne "party_id" } {
		lappend key [set $element]
	    }
	}
	if { [info exists quantities($key)] } {
	    incr quantities($key)
	} else {
	    set quantities($key) 1
	    lappend keys $key
	}
    }
    # now we figure out how many list items each
    # key has then then we sort recursively
    
    set count [llength $key]
    while { $count > 0 } {
	incr count -1
	set keys [lsort -dictionary -index $count $keys]
    }
    
    foreach key $keys {
	set command [list template::multirow append report]
	set count 0
	foreach part $key {
	    if { $part eq "" } {
		set part [_ intranet-contacts.--Not_Specified--]
		if { $format ne "csv" } {
		    set part "<em>${part}</em>"
		}
	    }
	    lappend command $part
	}
	lappend command $quantities($key)
	eval $command
    }
    list::write_output -name report

}





# create forms to add/remove columns from the multirow
if { [llength $add_columns] > 0 } {
    set add_columns [concat [list [list "[_ intranet-contacts.--add_column--]" "" ""]] $add_columns]
}
if { [llength $remove_columns] > 0 } {
    set remove_columns [concat [list [list "[_ intranet-contacts.--remove_column--]" "" ""]] $remove_columns]
}

set extended_columns_preserved $extended_columns
set report_p_preserved $report_p

ad_form \
    -name "add_column_form" \
    -method "GET" \
    -export {format search_id query page page_size orderby report_p} \
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

set report_p $report_p_preserved
ad_form \
    -name "remove_column_form" \
    -method "GET" \
    -export {format search_id query page page_size orderby report_p} \
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

