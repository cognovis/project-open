ad_library {

    Contact search condition type procs

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2005-07-18
    @cvs-id $Id$

}

namespace eval contacts:: {}
namespace eval contacts::search:: {}
namespace eval contacts::search::condition_type:: {}

ad_proc -public contacts::search::condition_type {
    -type:required
    -request:required
    {-var_list ""}
    {-form_name ""}
    {-object_type "party"}
    {-prefix "condition"}
    {-package_id ""}
} {
    This proc defers its responses to all other <a href="/api-doc/proc-search?show_deprecated_p=0&query_string=contacts::search::condition_type::&source_weight=0&param_weight=3&name_weight=5&doc_weight=2&show_private_p=1&search_type=All+matches">contacts::search::condition_type::${type}</a> procs.

    @param type type <a href="/api-doc/proc-search?show_deprecated_p=0&query_string=contacts::search::condition_type::&source_weight=0&param_weight=3&name_weight=5&doc_weight=2&show_private_p=1&search_type=All+matches">contacts::search::condition_type::${type}</a> we defer to
    @param request
    must be one of the following:
    <ul>
    <li><strong>ad_form_widgets</strong> - returns element(s) string(s) suitable for inclusion in the form section of <a href="/api-doc/proc-view?proc=ad_form">ad_form</a></li>
    <li><strong>form_var_list</strong> - returns 1 if we no longer need to add widgets to the form</li>
    <li><strong>sql</strong> - returns the sql</li>
    <li><strong>pretty</strong> - </li>
    <li><strong>type_name</strong> - returns the name of the type of condition like "Attributes"</li>
   </ul>
    @param form_name The name of the template_form or ad_form being used
} {
    if { $package_id eq "" } {
	    set package_id [ad_conn package_id]
    }

    if { [contacts::search::condition_type_exists_p -type $type] } {
        switch $request {
            ad_form_widgets {}
            form_var_list {}
	        sql {}
	        pretty {}
	        type_name {}
	    }
	    set output [contacts::search::condition_type::${type} -request $request -form_name $form_name -var_list $var_list -party_id "acs_objects.object_id" -object_type $object_type -prefix $prefix -package_id $package_id]
	    return $output
    } else {
	    # the widget requested did not exist
	    ns_log Debug "Contacts: the contacts search condition type \"${type}\" was requested and the associated ::contacts::search::condition_type::${type} procedure does not exist"
    }
}

ad_proc -private contacts::search::condition_types {
    {-package_id ""}
} {
    Return all widget procs. Each list element is a list of the first then pretty_name then the widget
} {
    if { $package_id eq "" } {
	    set package_id [ad_conn package_id]
    }
    set condition_types [list]
    set all_procs [::info procs "::contacts::search::condition_type::*"]
    foreach condition_type $all_procs {
	    if { [string is false [regsub {__arg_parser} $condition_type {} condition_type]] } {
	        regsub {::contacts::search::condition_type::} $condition_type {} condition_type
            lappend condition_types [list [contacts::search::condition_type -type $condition_type -request "type_name" -package_id $package_id] $condition_type]
	    }
    }
    return [::ams::util::localize_and_sort_list_of_lists -list $condition_types]
}

ad_proc -private contacts::search::condition_type_exists_p {
    {-type}
} {
    Return 1 if it exists and 0 if not
} {
    return [string is false [empty_string_p [info procs "::contacts::search::condition_type::${type}"]]]
}



ad_proc -private contacts::search::condition_type::attribute {
    -request:required
    -package_id:required
    {-var_list ""}
    {-party_id "acs_objects.object_id"}
    {-form_name ""}
    {-object_type}
    {-subtype_id ""}
    {-prefix ""}
    {-without_arrow_p "f"}
    {-only_multiple_p "f"}
    {-null_display "- - - - - -"}
} {
    Return all widget procs. Each list element is a list of the first then pretty_name then the widget

    @param party_id the sql column where a party id can be found (normally something like parties.party_id, but it might be persons.person_id, or organizations.organization_id)
    @param without_arrow_p Show the elementes in the select menu without the "->"
    @param only_multiple_p Only show those elements that have multiple choices
} {
    
    switch $request {
        ad_form_widgets {
            
            #######################################
            #
            # Code to display the options for the
            # attribute
            #
            #######################################
            
            set attribute_id [ns_queryget ${prefix}attribute_id]
            
            if { [exists_and_not_null attribute_id] } {
                set element [::im::dynfield::Element get_instance_from_db -id $attribute_id]
                set widget [::im::dynfield::Widget get_widget -widget_name [$element widget_name]]

                set attrprefix "${prefix}[$element attribute_name]__"
                set operand [ns_queryget "${attrprefix}operand"]
                # we must use the operand in the var prefix because
                # this will reset the vars if somebody changes the operand
                set var1 "${attrprefix}${operand}__var1"
                set var2 "${attrprefix}${operand}__var2"
                set ${var1} [ns_queryget ${var1}]

                # Deal with Dates properly
                if { [template::element::exists $form_name $var1] } {
                    if { [template::element::get_property $form_name $var1 widget] == "date" } {
                        set ${var1} [join \
                                         [template::util::date::get_property linear_date_no_time \
                                              [template::element::get_value $form_name $var1] \
                                             ] \
                                         "-"]
                    }
                }
                set ${var2} [ns_queryget ${var2}]
                
                # Now get the var elements and operand options
                set operand_options [$widget operand_options]
                set var_elements [list]
                
                switch [$widget widget] {
                    checkbox - multiselect - category_tree - im_category_tree - radio - select - generic_sql - im_cost_center_tree {
			            if { $operand == "selected" || $operand == "not_selected" } {
                            set var_elements [$element form_element -form_element_name $var1]
			            }
                    }
                    date {
                        set operand_options [$widget operand_options]
                        if { [lsearch [list "more_than" "less_than"] $operand] >= 0 } {
                            set interval_options [list \
                                                      [list [_ intranet-contacts.years] years] \
                                                      [list [_ intranet-contacts.months] months] \
                                                      [list [_ intranet-contacts.days] days] \
                                                     ]
                            lappend var_elements [list ${var1}:integer(text) [list label {}] [list html [list size 2 maxlength 3]]]
                            lappend var_elements [list ${var2}:text(select) [list label {}] [list options $interval_options] [list after_html [list [_ intranet-contacts.ago]]]]
			            } elseif { [lsearch [list "recurrence_within_next" "recurrence_within_last"] $operand] >= 0 } {
                            set interval_options [list \
                                                      [list [_ intranet-contacts.days] days] \
                                                      [list [_ intranet-contacts.months] months] \
                                                     ]
                            lappend var_elements [list \
						      ${var1}:integer(text) \
						      [list label {}] \
						      [list html [list size 2 maxlength 3]] \
						     ]
                            lappend var_elements [list \
						      ${var2}:text(select) \
						      [list label {}] \
						      [list options $interval_options] \
						     ]
			            } elseif { [exists_and_not_null operand] } {
                            lappend var_elements [list ${var1}:date(date) [list label {}]]
                        }
                    }
                    default {
                        set var_elements [$element form_element -form_element_name $var1]
                    }
                }
            }
            
            set form_elements [list]

            # Display the attribute options.
            if { !$only_multiple_p } {
                
                
                if {$subtype_id eq ""} {

                    # Get the subtype_id for the object_type. Only the ones in this group might be searched
                    set subtype_id [ams::list::get_list_id -object_type $object_type -list_name $object_type]
                }
		        
		        set attribute_options [db_list_of_lists get_all_attributes "
				select 
					aa.pretty_name,
					da.attribute_id
				from
					acs_attributes aa, 
					im_dynfield_attributes da,
					im_dynfield_type_attribute_map tam
				where
					tam.attribute_id = da.attribute_id
					and tam.object_type_id = :subtype_id
					and da.deprecated_p = 'f'
					and da.acs_attribute_id = aa.attribute_id
                "]
	            
	        } else {
		        set attribute_options [contacts::attribute::options_attribute]
	        }
	        
            set sorted_options [ams::util::localize_and_sort_list_of_lists -list $attribute_options]
            set attribute_options [list [list "$null_display" ""]]
            foreach op $sorted_options {
		        if { $without_arrow_p } {
		            lappend attribute_options [list "[lindex $op 0]" "[lindex $op 1]"]
		        } else {
		            lappend attribute_options [list "[lindex $op 0] ->" "[lindex $op 1]"]
		        }
            }
            
            # This is the form_elements with the list of attributes
            lappend form_elements [list \
                                       ${prefix}attribute_id:text(select),optional \
                                       [list label {}] \
                                       [list options $attribute_options] \
                                       [list html [list onChange "javascript:acs_FormRefresh('$form_name')"]] \
                                       [list value $attribute_id] \
                                      ]
            
            if { [exists_and_not_null attribute_id] } {
                # now we add operand options that are available to anybody
                lappend operand_options [list "[_ intranet-contacts.is_set]" "set"] [list "[_ intranet-contacts.is_not_set]" "not_set"]

                lappend form_elements [list \
                                           ${attrprefix}operand:text(select),optional \
                                           [list label {}] \
                                           [list options [concat $operand_options]] \
                                           [list html [list onChange "javascript:acs_FormRefresh('$form_name')"]] \
                                          ]

                if { $operand != "set" && $operand != "not_set" } {
                    # there could be variable elements so we add them here
                    set form_elements [concat $form_elements $var_elements]
                }
            }
            return $form_elements
        }
        form_var_list {

            ###########################################
            #
            # This gets the information for storing
            # It is executed once all choices for elements
            # have been made.
            # 
            ############################################

            set attribute_id [ns_queryget ${prefix}attribute_id]
            if { [exists_and_not_null attribute_id] } {
                set attribute_name [im_dynfield::attribute::get_name_from_id -attribute_id $attribute_id]
                set prefix "${prefix}${attribute_name}__"
                set operand [ns_queryget "${prefix}operand"]

                if { $operand == "set" || $operand == "not_set" } {
                    return [list $attribute_id $operand]
                } elseif { [exists_and_not_null operand] } {
                    set var1 "${prefix}${operand}__var1"
                    set var2 "${prefix}${operand}__var2"
                    set ${var1} [ns_queryget ${var1}]
                    if { [template::element::exists $form_name $var1] } {
                        if { [template::element::get_property $form_name $var1 widget] == "date" } {
                            set ${var1} [join \
                                             [template::util::date::get_property linear_date_no_time \
                                                  [template::element::get_value $form_name $var1] \
                                                 ] \
                                             "-"]
                        }
                    }
                    set ${var2} [ns_queryget ${var2}]
                    if { [exists_and_not_null ${var1}] } {
                        set results [list $attribute_id $operand]
                        lappend results [set ${var1}]
                        if { [exists_and_not_null ${var2}] } {
                            lappend results [set ${var2}]
                        }
                        return $results
                    } else {
                        return {}
                    }
                } else {
                    return {}
                }
            }
        }
        sql - pretty {
            
            #############################
            # 
            # This code will be executed
            # when displaying a search
            #
            #############################
            set attribute_id [lindex $var_list 0]
            set element [::im::dynfield::Element get_instance_from_db -id $attribute_id]
            set widget [::im::dynfield::Widget get_widget -widget_name [$element widget_name]]
	    set attribute_name [im_dynfield::attribute::get_name_from_id -attribute_id $attribute_id]

            if { $request == "pretty" } {
                set attribute_pretty [$element pretty_name]
            } else {
                set attribute_pretty "[_ intranet-contacts.irrelevant]"
            }
            
            set operand [lindex $var_list 1]
            set value [string tolower [lindex $var_list 2]]

            switch $operand {
                set {
                    set output_pretty "[_ intranet-contacts.lt_attribute_pretty_is_s]"
                    set output_code "$attribute_name is not null"
                }
                not_set {
                    set output_pretty "[_ intranet-contacts.lt_attribute_pretty_is_n]"
                    set output_code "$attribute_name is null"
                }
                default {
                    set widget_type [$widget widget]
                    if {$widget_type eq "text"} {
                        switch [$widget acs_datatype] {
                            integer - number - float {
                                set widget_type "number"
                            }
                        }
                    }
                    switch $widget_type {
                        checkbox - multiselect - category_tree - im_category_tree - radio - select - generic_sql - im_cost_center_tree {
                            # The value needs to be refined to include the subtypes.
                            if { $request == "pretty" } {
                                set option_pretty [im_category_from_id $value]
                            } else {
                                set option_pretty ""
                            }

                            switch $operand {
                                selected {
                                    set output_pretty "[_ intranet-contacts.lt_attribute_pretty_is_s_1]"
                                    set output_code "[$element attribute_name] = '$value'"
                                }
                                not_selected {
                                    set output_pretty "[_ intranet-contacts.lt_attribute_pretty_is_n_1]"
                                    set output_code "[$element attribute_name] != '$value'"
                                }
                            }
                        }
                        text {
                            switch $operand  {
                                contains {
                                    set output_pretty "[_ intranet-contacts.lt_attribute_pretty_cont]"
                                    set output_code "lower([$element attribute_name]) like lower('%$value%')"
                                }
                                not_contains {
                                    set output_pretty "[_ intranet-contacts.lt_attribute_pretty_does]"
                                    set output_code "lower([$element attribute_name]) not like lower('%$value%')"
                                }
                            }
                        }
                        number {
                            switch $operand {
                                is {
                                    set output_pretty "[_ intranet-contacts.lt_attribute_pretty_is_s_2]"
                                    set output_code "[$element attribute_name] = '$value'"
                                }
                                greater_than {
                                    set output_pretty "[_ intranet-contacts.lt_attribute_pretty_is_g]"
                                    set output_code "[$element attribute_name] > '$value'"
                                }
                                less_than {
                                    set output_pretty "[_ intranet-contacts.lt_attribute_pretty_is_l]"
                                    set output_code "[$element attribute_name] < '$value'"
                                }
                            }
                        }
                        date {
			                set interval "$value [string tolower [lindex $var_list 3]]"
                            switch $operand {
                                less_than {
                                    set output_pretty "[_ intranet-contacts.lt_attribute_pretty_less_than]"
                                    set output_code "[$element attribute_name] > ( now() - '$interval'::interval )"
                                }
                                more_than {
                                    set output_pretty "[_ intranet-contacts.lt_attribute_pretty_more_than]"
                                    set output_code "[$element attribute_name] < ( now() - '$interval'::interval )"
                                }
                                recurrence_within_next {
				                    set output_pretty "[_ intranet-contacts.lt_attribute_pretty_within_next_]"
                                    set output_code "[$element attribute_name] < ( now() + '$interval'::interval )\n    and contacts_util__next_instance_of_date([$element attribute_name]::timestamptz) >= now()"
				                }
			                    recurrence_within_last {
				                    set output_pretty "[_ intranet-contacts.lt_attribute_pretty_within_last_]"
                                    set output_code "[$element attribute_name] > ( now() - '$interval'::interval ) + '1 year'::interval )\n     and contacts_util__next_instance_of_date([$element attribute_name]::timestamptz) <= ( now() + '1 year'::interval )"
				                }
                                after {
				                    set value_pretty [lc_time_fmt $value "%q"]
                                    set output_pretty "[_ intranet-contacts.lt_attribute_pretty_is_a]"
                                    set output_code "[$element attribute_name] > '$value'::timestamptz"
                                }
                                before {
				                    set value_pretty [lc_time_fmt $value "%q"]
                                    set output_pretty "[_ intranet-contacts.lt_attribute_pretty_is_a]"
                                    set output_code "[$element attribute_name] < '$value'::timestamptz"
                                }
                            }
                        }
                    }
                }
            }

            if { $request == "pretty" } {
                return $output_pretty
            } else {
                return $output_code
            }
        }
        type_name {
            return [_ intranet-contacts.Attribute]
        }
    }
}


ad_proc -private contacts::search::condition_type::subtype {
    -request:required
    -package_id:required
    {-var_list ""}
    {-form_name ""}
    {-party_id ""}
    {-prefix "contact"}
    -object_type:required
} {

    Return all widget procs. Each list element is a list of the first then pretty_name then the widget

    @param party_id the sql column where a party id can be found (normally something like parties.party_id, but it might be persons.person_id, or organizations.organization_id)
} {
    set operand  [ns_queryget "${prefix}operand"]
    set subtype_id [ns_queryget "${prefix}subtype_id"]
    set subtype_category [im_dynfield::type_category_for_object_type -object_type $object_type]
    
    switch $request {
        ad_form_widgets {
            set user_id [ad_conn user_id]
            set form_elements [list]
            set operand_options [list \
                                     [list "[_ intranet-contacts.contact_is_in_-]" "in"] \
                                     [list "[_ intranet-contacts.contact_is_not_in_-]" "not_in"] \
                            ]

            set subtype_category [im_dynfield::type_category_for_object_type -object_type $object_type]

            lappend form_elements [list ${prefix}operand:text(select) [list label {}] [list options $operand_options] [list value $operand]]
            lappend form_elements [list ${prefix}subtype_id:integer(im_category_tree) [list label {}] [list custom [list category_type $subtype_category]] [list value $subtype_id]]
            return $form_elements
        }
        form_var_list {
            if { [exists_and_not_null operand] && [exists_and_not_null subtype_id] } {
		        return [list $operand $subtype_id]
            }
            return {}
        }
        sql - pretty {
            set operand [lindex $var_list 0]
            set subtype_id [lindex $var_list 1]
            set title [im_category_from_id $subtype_id]
            if { $title eq "" } {
                # this list has been deleted or they don't have permission to read it any more
                if { $request eq "pretty" } {
                    return "[_ intranet-contacts.Subtype] [_ intranet-contacts.Deleted]"
                } else {
                    return " t = f "
                }
            }
            switch $operand {
                in {
                    set output_pretty "[_ intranet-contacts.lt_The_contact_in_list]"
                    if {$object_type eq "person"} {
                        # work with groups
                        set output_code "${party_id} in (select gdmm.member_id from group_distinct_member_map gdmm, im_categories c where c.aux_int1 = gdmm.group_id and category_id = $subtype_id)"
                    } else {
                        # Get the column and table
                        db_1row type_tables "select id_column,type_column,status_type_table from acs_object_types where object_type = :object_type"
                        set output_code "${party_id} in ( select ${status_type_table}.$id_column from $status_type_table where $type_column = $subtype_id )"                        
                    }
                }
                not_in {
                    set output_pretty "[_ intranet-contacts.lt_The_contact_NOT_in_li]"
                    if {$object_type eq "person"} {
                        # work with groups
                        set output_code "${party_id} not in (select gdmm.member_id from group_distinct_member_map gdmm, im_categories c where c.aux_int1 = gdmm.group_id and category_id = $subtype_id)"
                    } else {
                        db_1row type_tables "select id_column,type_column,status_type_table from acs_object_types where object_type = :object_type"
                        set output_code "${party_id} not in ( select ${status_type_table}.$id_column from $status_type_table where $type_column = $subtype_id )"                        
                    }
                }
            }
            if { $request == "pretty" } {
                return $output_pretty
            } else {
                return $output_code
            }
        }
        type_name {
            return [_ intranet-contacts.Subtype]
        }
    }
}



ad_proc -private contacts::search::condition_type::relationship {
    -request:required
    -package_id:required
    {-var_list ""}
    {-form_name ""}
    {-party_id ""}
    {-prefix "contact"}
    {-object_type ""}
} {
    Return all widget procs. Each list element is a list of the first then pretty_name then the widget
} {
    set role      [ns_queryget "${prefix}role"]
    set operand   [ns_queryget "${prefix}operand"]
    set times     [ns_queryget "${prefix}${role}times"]
    set search_id [ns_queryget "${prefix}${role}search_id"]
    set contact_id [ns_queryget "${prefix}${role}contact_id"]

    if { ![exists_and_not_null object_type] } {
	    set object_type "party"
    }
    switch $request {
        ad_form_widgets {
            set form_elements [list]

	        set rel_options [db_list_of_lists get_rels {
                select acs_rel_type__role_pretty_name(primary_role) as pretty_name,
                primary_role as role
                from contact_rel_types
                where secondary_object_type in ( :object_type, 'party' )
                group by primary_role
                order by upper(acs_rel_type__role_pretty_name(primary_role))
	        }]
	        set rel_options [ams::util::localize_and_sort_list_of_lists -list $rel_options]
	        set rel_options [concat [list [list "" ""]] $rel_options]
            lappend form_elements [list \
                                       ${prefix}role:text(select) \
                                       [list label [_ intranet-contacts.with]] \
                                       [list options $rel_options] \
                                      ]

            set operand_options [list \
                                     [list "[_ intranet-contacts.exists]" "exists"] \
                                     [list "[_ intranet-contacts.does_not_exists]" "not_exists"] \
                                     [list "[_ intranet-contacts.is] ->" "is"] \
                                     [list "[_ intranet-contacts.is_not] ->" "not_is"] \
                                     [list "[_ intranet-contacts.in_the_search] ->" "in_search"] \
                                     [list "[_ intranet-contacts.not_in_the_search] ->" "not_in_search"] \
                                    ]

#                                     [list "[_ intranet-contacts.exists_at_least] ->" "min_number"] \
#                                     [list "[_ intranet-contacts.exists_at_most] ->" "max_number"] \

            lappend form_elements [list \
                                       ${prefix}operand:text(select),optional \
                                       [list label {}] \
                                       [list options $operand_options] \
                                       [list html [list onChange "javascript:acs_FormRefresh('$form_name')"]] \
                                      ]

            # login and not_login do not need special elements
	        switch $operand {
		        min_number - max_number {
		            lappend form_elements [list ${prefix}${role}times:integer(text) [list label {}] [list html [list size 2 maxlength 4]] [list after_html [_ intranet-contacts.Times]]]
		}
		    in_search - not_in_search {
		        set user_id [ad_conn user_id]
		        set search_options [list [list "" "" ""]]
		        # the limitiation on contact_search_conditions is there to prevent infinit loops of search in another search
		        db_foreach get_my_searches {
                        select acs_objects.title,
			       contact_searches.search_id,
                               contact_searches.owner_id
                          from contact_searches,
                               acs_objects
                         where contact_searches.owner_id in ( :user_id, :package_id )
                           and contact_searches.search_id = acs_objects.object_id
                           and acs_objects.title is not null
                           and not contact_searches.deleted_p
                           and acs_objects.package_id = :package_id
                           and contact_searches.search_id not in ( select search_id from contact_search_conditions where var_list like ('in_searc%') or var_list like ('not_in_searc%') )
                         order by CASE WHEN contact_searches.owner_id = :package_id THEN '1'::integer ELSE '2' END, lower(acs_objects.title)
		        } {
			        if { $owner_id eq $package_id } {
			            set section_title [_ intranet-contacts.Public_Searches]
			        } else {
			            set section_title [_ intranet-contacts.My_Searches]
			        }
			        lappend search_options [list $title $search_id $section_title]
		        }

		        lappend form_elements [list \
					       ${prefix}${role}search_id:integer(select_with_optgroup) \
					       [list label {}] \
					       [list options $search_options] \
					      ]
		    }
		    is - not_is {
		        lappend form_elements [list \
					       ${prefix}${role}contact_id:contact_search(contact_search) \
					       [list label {}] \
					      ]
		                }
            }
            return $form_elements
        }
        form_var_list {
            if { [exists_and_not_null role] && [exists_and_not_null operand] } {
		        set results [list $role $operand]
		        switch $operand {
		            min_number - max_number {
			            if { [exists_and_not_null times] } {
			                lappend results $times
			            } else {
			                set not_complete_p 1
			            }
		            }
		            in_search - not_in_search {
			            if { [exists_and_not_null search_id] } {
			                lappend results $search_id
		                } else {
		                    set not_complete_p 1
			            }
		            }
		            is - not_is {
			            if { [exists_and_not_null contact_id] && [template::form is_valid $form_name] } {
			                lappend results $contact_id
			            } else {
			                set not_complete_p
			            }
		            }
		        }
		        if { ![exists_and_not_null not_complete_p] } {
		            return $results
		        }
            }
	        return {}
        }
        sql - pretty {
            set role [lindex $var_list 0]
	    set union "
(
( select acs_rels.object_id_one as party_id
    from acs_rels
   where acs_rels.rel_type in ( select rel_type
                         from acs_rel_types
                        where role_two = '$role' ) 
)
union
( select acs_rels.object_id_two as party_id
    from acs_rels
   where acs_rels.rel_type in ( select rel_type
                                  from acs_rel_types
                                   where role_one = '$role' )
)
)
"
	    set union_reverse "
(
( select acs_rels.object_id_two as party_id
    from acs_rels
   where acs_rels.rel_type in ( select rel_type
                                  from acs_rel_types
                                 where role_two = '$role' )
)
union
( select acs_rels.object_id_one as party_id
    from acs_rels
   where acs_rels.rel_type in ( select rel_type
                                  from acs_rel_types
                                 where role_one = '$role' )
)
)
"


	    set operand [lindex $var_list 1]
	    switch $operand {
		    min_number - max_number { set times [lindex $var_list 2] }
		    in_search - not_in_search { set search_id [lindex $var_list 2] }
            is - not_is {
                set contact_id [lindex $var_list 2]
                set contact_name [contact::name -party_id $contact_id]
                set contact_url  [contact::url -party_id $contact_id]
            }
	    }
	    if { $request == "pretty" } {
		    if { [exists_and_not_null times] } {
		        if { $times != 1 } {
			        set role [lang::util::localize [db_string get_pretty_role { select pretty_plural from acs_rel_roles where role = :role } -default {}]]
		        } else {
		            set role [lang::util::localize [db_string get_pretty_role { select pretty_name from acs_rel_roles where role = :role } -default {}]]
                }
		    } else {
		      set role [lang::util::localize [db_string get_pretty_role { select pretty_name from acs_rel_roles where role = :role } -default {}]]
            }
	    }
        switch $operand {
		    exists {
		        set output_pretty [_ intranet-contacts.lt_role_exists]
		        set output_code "$party_id in $union"
		    }
		    not_exists {
		        set output_pretty [_ intranet-contacts.lt_role_not_exists]
		        set output_code "$party_id not in $union"
		    }
		    max_number {
		        set output_pretty [_ intranet-contacts.lt_At_most_times_role_are_related]
		        set output_code "$party_id in 
                ( select party_id from
                   (select count(party_id) as rel_count, party_id from
                   $union_reverse rels
                   group by party_id
                   ) rel_count_and_id
                 where rel_count <= $times )"
		    }
		    min_number {
		        set output_pretty [_ intranet-contacts.lt_At_least_times_role_are_related]
		        set output_code "$party_id in 
                ( select party_id from
                 ( select count(party_id) as rel_count, party_id from
                    $union_reverse rels
                    group by party_id
                 ) rel_count_and_id
                 where rel_count >= $times )"
		    }
            in_search {
                set search_link "<a href=\"[export_vars -base {./} -url {search_id}]\">[contact::search::title -search_id $search_id]</a>"
                set output_pretty [_ intranet-contacts.lt_role_in_the_search_search_link]
                set output_code "
$party_id in ( select CASE WHEN acs_rel_types.role_two = '$role' THEN acs_rels.object_id_one ELSE acs_rels.object_id_two END as party_id
                from acs_rels, acs_rel_types
               where acs_rels.rel_type = acs_rel_types.rel_type
                 and ( acs_rel_types.role_two = '$role' or acs_rel_types.role_one = '$role' )
                 and [contact::party_id_in_sub_search_clause -search_id $search_id -party_id "CASE WHEN acs_rel_types.role_two = '$role' THEN acs_rels.object_id_two ELSE acs_rels.object_id_one END"]
            )
"
            }
            not_in_search {
                    set search_link "<a href=\"[export_vars -base {./} -url {search_id}]\">[contact::search::title -search_id $search_id]</a>"
                    set output_pretty [_ intranet-contacts.lt_role_not_in_the_search_search_link]
                    set output_code "
$party_id not in ( select CASE WHEN acs_rel_types.role_two = '$role' THEN acs_rels.object_id_one ELSE acs_rels.object_id_two END as party_id
                from acs_rels, acs_rel_types
               where acs_rels.rel_type = acs_rel_types.rel_type
                 and ( acs_rel_types.role_two = '$role' or acs_rel_types.role_one = '$role' )
                 and [contact::party_id_in_sub_search_clause -not -search_id $search_id -party_id "CASE WHEN acs_rel_types.role_two = '$role' THEN acs_rels.object_id_two ELSE acs_rels.object_id_one END"]
            )
"
            }
            is {
                 set output_pretty [_ intranet-contacts.lt_role_is_contact_name]
                 set output_code "
$party_id in ( select CASE WHEN acs_rel_types.role_two = '$role' THEN acs_rels.object_id_one ELSE acs_rels.object_id_two END as party_id
                from acs_rels, acs_rel_types
               where acs_rels.rel_type = acs_rel_types.rel_type
                 and ( 
                       ( acs_rel_types.role_two = '$role' and acs_rels.object_id_two = $contact_id )
                     or
                       ( acs_rel_types.role_one = '$role' and acs_rels.object_id_one = $contact_id )
                     )
             )
"
            }
            not_is {
                 set output_pretty [_ intranet-contacts.lt_role_is_not_contact_name]
                 set output_code "
$party_id not in ( select CASE WHEN acs_rel_types.role_two = '$role' THEN acs_rels.object_id_one ELSE acs_rels.object_id_two END as party_id
                from acs_rels, acs_rel_types
               where acs_rels.rel_type = acs_rel_types.rel_type
                 and ( 
                       ( acs_rel_types.role_two = '$role' and acs_rels.object_id_two = $contact_id )
                     or
                       ( acs_rel_types.role_one = '$role' and acs_rels.object_id_one = $contact_id )
                     )
                 )
"
                }
            }
            if { $request == "pretty" } {
                return $output_pretty
            } else {
                return $output_code
            }
        }
        type_name {
            return [_ intranet-contacts.Relationship]
        }
    }
}




###################



# The contact conditions are disabled for the moment
if {0} {
ad_proc -private contacts::search::condition_type::contact {
    -request:required
    -package_id:required
    {-var_list ""}
    {-form_name ""}
    {-party_id ""}
    {-prefix "contact"}
    {-object_type ""}
} {
    Return all widget procs. Each list element is a list of the first then pretty_name then the widget
} {
    set operand [ns_queryget "${prefix}operand"]
    set var1 "${prefix}${operand}var1"
    set var2 "${prefix}${operand}var2"
    set ${var1} [ns_queryget ${var1}]
    set ${var2} [ns_queryget ${var2}]

    switch $request {
        ad_form_widgets {

            set form_elements [list]

            set contact_options [list]
	    lappend contact_options [list "[_ intranet-contacts.in_the_search] ->" "in_search"]
	    lappend contact_options [list "[_ intranet-contacts.not_in_the_search] ->" "not_in_search"]

	    if { [parameter::get -boolean -package_id $package_id -parameter "ContactPrivacyEnabledP" -default "0"] } {
		lappend contact_options [list "[_ intranet-contacts.has_closed_down_or_is_deceased]" "privacy_gone_true"]
		lappend contact_options [list "[_ intranet-contacts.has_not_closed_down_and_is_not_deceased]" "privacy_gone_false"]
		lappend contact_options [list "[_ intranet-contacts.emailing_not_allowed]" "privacy_email_false"]
		lappend contact_options [list "[_ intranet-contacts.emailing_allowed]" "privacy_email_true"]
		lappend contact_options [list "[_ intranet-contacts.mailing_not_allowed]" "privacy_mail_false"]
		lappend contact_options [list "[_ intranet-contacts.mailing_allowed]" "privacy_mail_true"]
		lappend contact_options [list "[_ intranet-contacts.phoning_not_allowed]" "privacy_phone_false"]
		lappend contact_options [list "[_ intranet-contacts.phoning_allowed]" "privacy_phone_true"]

	    }

	    lappend contact_options [list "[_ intranet-contacts.lt_updated_in_the_last_-]" "update"]
	    lappend contact_options [list "[_ intranet-contacts.lt_not_updated_in_the_la]" "not_update"]
	    lappend contact_options [list "[_ intranet-contacts.lt_interacted_in_the_last_-]" "interacted"]
	    lappend contact_options [list "[_ intranet-contacts.lt_not_interacted_in_the_la]" "not_interacted"]
	    lappend contact_options [list "[_ intranet-contacts.lt_interacted_between_-]" "interacted_between"]
	    lappend contact_options [list "[_ intranet-contacts.lt_not_interacted_betwe]" "not_interacted_between"]
	    lappend contact_options [list "[_ intranet-contacts.lt_commented_on_in_last_]" "comment"]
	    lappend contact_options [list "[_ intranet-contacts.lt_not_commented_on_in_l]" "not_comment"]
	    lappend contact_options [list "[_ intranet-contacts.lt_created_in_the_last_-]" "created"]
	    lappend contact_options [list "[_ intranet-contacts.lt_not_created_in_the_la]" "not_created"]

            if { $object_type == "person" } {
                lappend contact_options [list "[_ intranet-contacts.has_logged_in]" "login"]
                lappend contact_options [list "[_ intranet-contacts.has_never_logged_in]" "not_login"]
                lappend contact_options [list "[_ intranet-contacts.lt_has_logged_in_within_]" "login_time"]
                lappend contact_options [list "[_ intranet-contacts.lt_has_not_logged_in_wit]" "not_login_time"]
            }

            lappend form_elements [list \
                                       ${prefix}operand:text(select) \
                                       [list label {}] \
                                       [list options $contact_options] \
                                       [list html [list onChange "javascript:acs_FormRefresh('$form_name')"]] \
                                      ]

            # login and not_login do not need special elements
	    # the limitiation on contact_search_conditions is there to prevent infinit loops of search in another search
            if { [lsearch [list in_search not_in_search] ${operand}] >= 0 } {
                set user_id [ad_conn user_id]
		set search_options [list [list "" "" ""]]
                db_foreach get_my_searches {
                        select acs_objects.title,
                               contact_searches.search_id,
                               contact_searches.owner_id
                          from contact_searches,
                               acs_objects
                         where contact_searches.owner_id in ( :user_id, :package_id )
                           and contact_searches.search_id = acs_objects.object_id
                           and acs_objects.title is not null
                           and not contact_searches.deleted_p
                           and acs_objects.package_id = :package_id
                           and contact_searches.search_id not in ( select search_id from contact_search_conditions where var_list like ('in_searc%') or var_list like ('not_in_searc%') )
                         order by CASE WHEN contact_searches.owner_id = :package_id THEN '1'::integer ELSE '2' END, lower(acs_objects.title)
		} {
		    if { $owner_id eq $package_id } {
			set section_title [_ intranet-contacts.Public_Searches]
		    } else {
			set section_title [_ intranet-contacts.My_Searches]
		    }
		    lappend search_options [list $title $search_id $section_title]
		}
                lappend form_elements [list \
                                           ${var1}:integer(select_with_optgroup),optional \
                                           [list label {}] \
                                           [list options $search_options] \
                                          ]
            } elseif { [lsearch [list interacted_between not_interacted_between] ${operand}] >= 0 } {
		lappend form_elements [list ${var1}:textdate [list label {}] [list after_html "and"]]
		lappend form_elements [list ${var2}:textdate [list label {}]]
	    } elseif { [lsearch [list privacy_gone_true privacy_gone_false privacy_email_true privacy_email_false privacy_mail_true privacy_mail_false privacy_phone_true privacy_phone_false] ${operand}] < 0 && $operand ne "" } {
                set interval_options [list \
                                          [list days days] \
                                          [list months months] \
                                          [list years years] \
                                         ]
                lappend form_elements [list ${var1}:integer(text) [list label {}] [list html [list size 3 maxlength 4]]]
                lappend form_elements [list ${var2}:text(select) [list label {}] [list options $interval_options]]
            }
            return $form_elements
        }
        form_var_list {
	    ns_log notice "$operand [set $var1] [set $var2]"
            if { [exists_and_not_null operand] } {
                switch ${operand} {
                    login - not_login {
                        return [set ${operand}]
                    }
		    privacy_gone_true - privacy_gone_false - privacy_email_true - privacy_email_false - privacy_mail_true - privacy_mail_false - privacy_phone_true - privacy_phone_false {
                        return ${operand}
                    }
                    in_search - not_in_search {
                        if { [string is integer [set ${var1}]] && [set ${var1}] ne "" } {
                            return [list ${operand} [set ${var1}]]
                        } else {
			     template::element::set_error $form_name ${var1} [_ intranet-contacts.Required]
			}
                    }
		    interacted_between - not_interacted_between {
			if { [exists_and_not_null ${var1}] && [exists_and_not_null ${var2}] } {
			    if { ![db_0or1row get_it " select 1 where '[set ${var1}]'::date <= '[set ${var2}]'::date "] } {
				template::element::set_error $form_name $var1 [_ intranet-contacts.Start_must_be_before_end]
			    }
			    if { [template::form::is_valid $form_name] } {
				return [list ${operand} [template::element::get_value $form_name $var1] [template::element::get_value $form_name $var2]]
			    }
			}
		    }
                    default {
                        if { [exists_and_not_null ${var1}] && [exists_and_not_null ${var2}] } {
                            return [list ${operand} [set ${var1}] [set ${var2}]]
                        }
                    }
                }
            }
	    return {}
        }
        sql - pretty {
            set operand [lindex $var_list 0]
            set interval "[lindex $var_list 1] [lindex $var_list 2]"
            set start_date [lindex $var_list 1]
	    set end_date [lindex $var_list 2]
            switch $operand {
                in_search {
                    set search_id [lindex $var_list 1]
                    set search_link "<a href=\"[export_vars -base {./} -url {search_id}]\">[contact::search::title -search_id $search_id]</a>"
                    set output_pretty "[_ intranet-contacts.lt_Contact_in_the_search_search_link]"
                    set output_code   [contact::party_id_in_sub_search_clause -search_id $search_id -party_id acs_objects.object_id]
                }
                not_in_search {
                    set search_id [lindex $var_list 1]
                    set search_link "<a href=\"[export_vars -base {./} -url {search_id}]\">[contact::search::title -search_id $search_id]</a>"
                    set output_pretty "[_ intranet-contacts.lt_Contact_not_in_the_search_search_link]"
                    set output_code   [contact::party_id_in_sub_search_clause -search_id $search_id -not -party_id acs_objects.object_id]
                }
                update {
                    set output_pretty "[_ intranet-contacts.lt_Contact_updated_in_th]"
                    set output_code   "CASE WHEN acs_objects.creation_date > ( now() - '$interval'::interval ) THEN 't'::boolean ELSE 'f'::boolean END"
                }
                not_update {
                    set output_pretty "[_ intranet-contacts.lt_Contact_not_updated_i]"
                    set output_code   "CASE WHEN creation_date > ( now() - '$interval'::interval ) THEN 'f'::boolean ELSE 't'::boolean END"
                }
                interacted - not_interacted - interacted_between - not_interacted_between {
		    if { [util_memoize [list im_table_exists acs_mail_log]] } {
			# mail-tracking is installed so we use this table as well as the contact_message_log
			set interacted_table "( select recipient_id, sent_date from acs_mail_log union select recipient_id, sent_date from contact_message_log ) as messages"
		    } else {
			set interacted_table "contact_message_log"
		    }
		    set start_date_pretty [lc_time_fmt $start_date %x]
		    set end_date_pretty [lc_time_fmt $end_date %x]
		    switch $operand {
			interacted {
			    set output_pretty "[_ intranet-contacts.lt_Contact_interacted_in_th]"
			    set output_code   "acs_objects.object_id in ( select distinct on (recipient_id) recipient_id from $interacted_table where sent_date > ( now() - '$interval'::interval ) order by recipient_id, sent_date desc )"
			}
			not_interacted {
			    set output_pretty "[_ intranet-contacts.lt_Contact_not_interacted_i]"
			    set output_code   "acs_objects.object_id not in ( select distinct on (recipient_id) recipient_id from $interacted_table where sent_date > ( now() - '$interval'::interval ) order by recipient_id, sent_date desc )"
			}
			interacted_between {
			    set output_pretty "[_ intranet-contacts.lt_Contact_interacted_between]"
			    set output_code   "acs_objects.object_id in ( select distinct on (recipient_id) recipient_id from $interacted_table where sent_date BETWEEN '${start_date}' AND '${end_date}' )"
			}
			not_interacted_between {
			    set output_pretty "[_ intranet-contacts.lt_Contact_not_interacted_bet]"
			    set output_code   "acs_objects.object_id not in ( select distinct on (recipient_id) recipient_id from $interacted_table where sent_date BETWEEN '${start_date}' AND '${end_date}' )"
			}
		    }  
		}
                comment {
                    set output_pretty "[_ intranet-contacts.lt_Contact_commented_on_]"
                    set output_code   "CASE WHEN (select creation_date from acs_objects where object_id in ( select comment_id from general_comments where object_id = object_id ) order by creation_date desc limit 1 ) > ( now() - '$interval'::interval ) THEN 't'::boolean ELSE 'f'::boolean END"
                }
                not_comment {
                    set output_pretty "[_ intranet-contacts.lt_Contact_not_commented]"
                    set output_code   "CASE WHEN (select creation_date from acs_objects where object_id in ( select comment_id from general_comments where object_id = object_id ) order by creation_date desc limit 1 ) > ( now() - '$interval'::interval ) THEN 'f'::boolean ELSE 't'::boolean END"
                }
                created {
                    set output_pretty "[_ intranet-contacts.lt_Contact_created_in_th]"
                    set output_code   "CASE WHEN ( select acs_objects.creation_date from acs_objects where acs_objects.object_id = object_id ) > ( now() - '$interval'::interval ) THEN 't'::boolean ELSE 'f'::boolean END"
                }
                not_created {
                    set output_pretty "[_ intranet-contacts.lt_Contact_not_created_i]"
                    set output_code   "CASE WHEN ( select acs_objects.creation_date from acs_objects where acs_objects.object_id = object_id ) > ( now() - '$interval'::interval ) THEN 'f'::boolean ELSE 't'::boolean END"
                }
                login {
                    set output_pretty "[_ intranet-contacts.lt_Contact_has_logged_in]"
                    set output_code   "CASE WHEN ( select n_sessions from users where user_id = object_id ) > 1 or ( select last_visit from users where user_id = $party_id ) is not null THEN 't'::boolean ELSE 'f'::boolean END"
                }
                not_login {
                    set output_pretty "[_ intranet-contacts.lt_Contact_has_never_log]"
                    set output_code   "CASE WHEN ( select n_sessions from users where user_id = $party_id ) > 1 or ( select last_visit from users where user_id = $party_id ) is not null THEN 'f'::boolean ELSE 't'::boolean END"
                }
                login_time {
                    set output_pretty "[_ intranet-contacts.lt_Contact_has_logged_in_1]"
                    set output_code   "CASE WHEN ( select last_visit from users where user_id = $party_id ) > ( now() - '$interval'::interval ) THEN 't'::boolean ELSE 'f'::boolean END"
                }
                not_login_time {
                    set output_pretty "[_ intranet-contacts.lt_Contact_has_not_logge]"
                    set output_code   "CASE WHEN ( select last_visit from users where user_id = $party_id ) > ( now() - '$interval'::interval ) THEN 'f'::boolean ELSE 't'::boolean END"
                }
		privacy_gone_true - privacy_gone_false - privacy_email_true - privacy_email_false - privacy_mail_true - privacy_mail_false - privacy_phone_true - privacy_phone_false {
		    switch ${operand} {
			privacy_gone_true {
			    set output_pretty [_ intranet-contacts.has_closed_down_or_is_deceased]
			    set condition "gone_p is true"
			}
			privacy_gone_false {
			    set output_pretty [_ intranet-contacts.has_not_closed_down_and_is_not_deceased]
			    set condition "gone_p is false"
			}
			privacy_email_false {
			    set output_pretty [_ intranet-contacts.emailing_not_allowed]
			    set condition "email_p is false"
			}
			privacy_email_true {
			    set output_pretty [_ intranet-contacts.emailing_allowed]
			    set condition "email_p is true"
			}
			privacy_mail_false {
			    set output_pretty [_ intranet-contacts.mailing_not_allowed]
			    set condition "mail_p is false"
			}
			privacy_mail_true {
			    set output_pretty [_ intranet-contacts.mailing_allowed]
			    set condition "mail_p is true"
			}
			privacy_phone_false {
			    set output_pretty [_ intranet-contacts.phoning_not_allowed]
			    set condition "phone_p is false"
			}
			privacy_phone_true {
			    set output_pretty [_ intranet-contacts.phoning_allowed]
			    set condition "phone_p is true"
			}
		    }
		    set output_code "${party_id} in ( select ${operand}${prefix}.party_id from contact_privacy ${operand}${prefix} where ${operand}${prefix}.$condition )"
		}
            }
	    if { ![exists_and_not_null output_pretty] } {
		set output_pretty "no pretty output"
	    }
	    if { ![exists_and_not_null output_code] } {
		set output_code "1 = 1"
	    }
            if { $request == "pretty" } {
                return $output_pretty
            } else {
                return $output_code
            }
        }
        type_name {
            return [_ intranet-contacts.Contact]
        }
    }
}

}



