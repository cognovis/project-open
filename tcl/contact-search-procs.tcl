ad_library {

  Support procs for the contacts package

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$

}

namespace eval contact:: {}
namespace eval contact::search:: {}
namespace eval contact::search::condition:: {}


ad_proc -public contact::search::new {
    {-search_id ""}
    {-title ""}
    {-owner_id ""}
    {-all_or_any}
    {-object_type}
    {-deleted_p "f"}
    {-package_id ""}
} {
    create a contact search
} {
    if { ![exists_and_not_null owner_id] } {
        set owner_id [ad_conn user_id]
    }
    if { ![exists_and_not_null package_id] } {
        set package_id [ad_conn package_id]
    }
    set var_list [list \
                      [list search_id $search_id] \
                      [list title $title] \
                      [list owner_id $owner_id] \
                      [list all_or_any $all_or_any] \
                      [list object_type $object_type] \
                      [list deleted_p $deleted_p] \
                      [list package_id $package_id] \
                      ]

    return [package_instantiate_object -var_list $var_list contact_search]
}

ad_proc -public contact::search::title {
    {-search_id ""}
} {
} {
    return [db_string select_title {} -default {}]
}


ad_proc -public contact::search::permitted {
    {-search_id:required}
    {-user_id ""}
} {
} {
    if { $search_id ne "" } {
	if { [db_0or1row select_search_info {}] } {
	    if { $user_id eq "" } {
		set user_id [ad_conn user_id]
	    }
	    if { ![acs_user::site_wide_admin_p -user_id $user_id] && $owner_id ne $user_id && $owner_id ne $package_id } {
		# the user is not site wide admin
		# the user does not own the search
		if { ![parameter::get -boolean -parameter "ViewOthersSearchesP" -default "0" -package_id $package_id] } {
		    ns_log notice "contact::search::permitted: user $user_id does not have permission to search_id $search_id (package $package_id owner $owner_id)"
		    ad_return_forbidden  [_ intranet-contacts.Permission_Denied] "<blockquote>[_ intranet-contacts.lt_Cannot_view_others_searches]</blockquote>"
		    ad_script_abort
		}
	    }
	}
    }
}

ad_proc -public contact::search::get {
    -search_id:required
    -array:required
} {
    Get the info on an ams_attribute
} {
    upvar 1 $array row
    db_1row select_search_info {} -column_array row
}

ad_proc -public contact::search::get_extensions { 
    -search_id:required
} {
} {
    return [db_list get_search_exensions {
	    select extend_column
	      from contact_search_extend_map
	     where search_id = :search_id
           }]
}

ad_proc -public contact::search::update {
    {-search_id ""}
    {-title ""}
    {-owner_id ""}
    {-all_or_any}
} {
    create a contact search
} {
    if { [contact::search::exists_p -search_id $search_id] } {
        db_dml update_search {
            update contact_searches
               set owner_id = :owner_id,
                   all_or_any = :all_or_any
             where search_id = :search_id
        }
        db_dml update_object {
            update acs_objects
               set title = :title
             where object_id = :search_id
	}
    }
}

ad_proc -public contact::search::delete {
    {-search_id ""}
} {
    create a contact search
} {
    db_dml delete_it { update contact_searches set deleted_p = 't' where search_id = :search_id }
}

ad_proc -public contact::search::exists_p {
    {-search_id ""}
} {
    create a contact search
} {
    if { [db_0or1row exists_p { select 1 from contact_searches where search_id = :search_id }] } {
        return 1
    } else {
        return 0
    }
}

ad_proc -public contact::search::owner_id {
    {-search_id ""}
} {
    create a contact search
} {
    return [db_string get_owner_id { select owner_id from contact_searches where search_id = :search_id } -default {}]
}

ad_proc -public contact::search::log {
    {-search_id}
    {-user_id ""}
} {
    log a search
} {
    if { ![exists_and_not_null user_id] } {
        set user_id [ad_conn user_id]
    }
    if { [contact::search::exists_p -search_id $search_id] } {
	db_1row log_search {}
    }
}

ad_proc -public contact::search::party_p {
    {-search_id}
    {-party_id}
    {-package_id ""}
} {
    Is the supplied party in the search. Cached.
} {
    if { $package_id eq "" } {
	if { [ad_conn package_key] eq "intranet-contacts" } {
	    set package_id [ad_conn package_id]
	} else {
	    acs_object::get -object_id $search_id -array search_object_info
	    set package_id $search_object_info(package_id)
	}
    }
    return [util_memoize [list ::contact::search::party_p_not_cached -search_id $search_id -party_id $party_id -package_id $package_id]]
}


ad_proc -public contact::search::flush_all {
} {
    Flush everything related to a search
} {
    db_foreach get_searches { select search_id from contact_searches } {
	contact::search::flush -search_id $search_id
    }
}

ad_proc -public contact::search::flush_results_counts {
} {
    Flush everything related to a search
} {
    util_memoize_flush_regexp "contact::search::results_count_not_cached"
    # previously we used results_count to figure out if a party was in a seach
    # as a performance enhancement this was moved to contact::search::party_p
    # we also need to flush all results for this proc now.
    util_memoize_flush_regexp "contact::search::party_p"
}

ad_proc -public contact::search::flush {
    {-search_id}
} {
    Flush everything related to a search
} {
    util_memoize_flush_regexp "contact::search(.*)$search_id"
    # we also flush the "all contacts" search, which doesn't have a search_id
    util_memoize_flush_regexp "contact::search(.*)-search_id {}"
}

ad_proc -public contact::search::results_count {
    {-search_id}
    {-query ""}
    {-package_id ""}
    {-category_id ""}
    {-group_id ""}
} {
    Get the total number of results from a search. Cached.
} {
    if { $package_id eq "" } {
	if { [ad_conn package_key] eq "intranet-contacts" } {
	    set package_id [ad_conn package_id]
	} else {
	    acs_object::get -object_id $search_id -array search_object_info
	    set package_id $search_object_info(package_id)
	}
    }
    return [util_memoize [list ::contact::search::results_count_not_cached -search_id $search_id -query $query -package_id $package_id -category_id $category_id -group_id $group_id]]
}

ad_proc -public contact::search::results_count_not_cached {
    {-search_id}
    {-query ""}
    {-package_id}
    {-category_id ""}
    {-group_id ""}
} {
    Get the total number of results from a search
} {

    set object_type [contact::search::object_type -search_id $search_id]
    set clauses [intranet-contacts::table_and_join_clauses -object_type $object_type -category_id $category_id]
    set contact_tables [lindex $clauses 0]
    set join_clauses [lindex $clauses 1]
    
    set search_clause [contact::search_clause -search_id $search_id -query $query -party_id "acs_objects.object_id" -limit_type_p "0"]

    set category_clause ""
    set condition_types [db_list get_condition_types {}]
    if {$category_id ne ""} {
        switch $object_type {
            im_company {
                set category_clause "company_type_id = :category_id"
            }
            im_office {
                set category_clause "office_type_id = :category_id"
            }
            person {
                set category_clause "persons.person_id in (select member_id from group_approved_member_map where group_id = :category_id)"
            }
        }
    } 

    if {$search_clause ne ""} {
        append join_clauses " and $search_clause"
    }
    
    if {$category_clause ne ""} {
        append join_clauses " and $category_clause"
    }
    return [db_string select_results_count {}]
}


ad_proc -public contact::search::results {
    {-search_id}
    {-query ""}
    {-package_id}
} {
    Get the party_ids returned for a search

    @param search_id ID of the search
    
} {

    if { [exists_and_not_null search_id] } {
	# Get the results depening on the object_type
    set object_type [contact::search::object_type -search_id $search_id]

	# The party column is the column of the object we look for
	# The item column is the column of the item which has the attributes
	# This allows to search for the attributes of an organization, but have the party
	# in a special search (employee search)
	
	switch $object_type {
	    party { 
		set party_column "parties.party_id"
		set item_column "parties.party_id"
	    }
	    organization {
		set party_column "organizations.organization_id"
		set item_column "organizations.organization_id"
	    } 
	    person {
		set party_column "persons.person_id"
		set item_column "persons.person_id"
	    } 
            employee {
		set party_column "acs_rels.object_id_one"
		set item_column "acs_rels.object_id_two"
	    }
	}
	set search_clause [contact::search_clause -and -search_id $search_id -query $query -party_id $party_column -limit_type_p "0"]

	set condition_types [db_list get_condition_types {}]
	if { [lsearch -exact $condition_types "attribute"] > -1 || [lsearch -exact $condition_types "contact"] > -1 } {
	    set cr_where "and cr_items.item_id = $item_column"
	    set cr_from "cr_items,"
	} else {
	    # We don't need to search for attributes so we don't need to join
	    # on the cr_items table. This should speed things up. This assumes
            # that packages other than contacts that add search condition
            # types do not need the revision_id column, and only needs the
            # party_id column. If this is not the case we may want to add a
            # callback here to check if another package needs the revisions 
            # table.
	    #
	    # If this needs to change you should also update the
            # contacts/lib/contacts.tcl file which behave the same way.
	    set cr_where ""
	    set cr_from ""
	}
    } else {
	set object_type "party"
	set page_query_name "contacts_pagination"
	set search_clause [contact::search_clause -and -query $query -search_id "" -party_id "parties.party_id" -limit_type_p "0"]
	set cr_from ""
	set cr_where ""
    }
    set results ""

    if { [catch {
	set results [db_list select_${object_type}_results {}]
    } errmsg] } {
	ns_log Error "contact::search::results contact search $search_id had a problem \n\n$errmsg"
    }

    return $results

}


ad_proc -private contact::party_id_in_sub_search_clause {
    {-search_id:required}
    {-party_id "party_id"}
    {-not:boolean}
    {-package_id ""}
} {
} {

    if { $package_id eq ""} {
	set package_id [ad_conn package_id]
    }

    # Get the results depening on the object_type
    set object_type [contact::search::object_type -search_id $search_id]
    
    # The party column is the column of the object we look for
    # The item column is the column of the item which has the attributes
    # This allows to search for the attributes of an organization, but have the party
    # in a special search (employee search)
    
    switch $object_type {
	party { 
	    set party_column "parties.party_id"
	    set item_column "parties.party_id"
	}
	organization {
	    set party_column "organizations.organization_id"
	    set item_column "organizations.organization_id"
	} 
	person {
	    set party_column "persons.person_id"
	    set item_column "persons.person_id"
	} 
	employee {
	    set party_column "acs_rels.object_id_one"
	    set item_column "acs_rels.object_id_two"
	}
    }
    set search_clause [contact::search_clause -and -search_id $search_id -party_id $party_column -limit_type_p "0"]
    
    set condition_types [db_list get_condition_types {}]
    if { [lsearch -exact $condition_types "attribute"] > -1 || [lsearch -exact $condition_types "contact"] > -1 } {
	set cr_where "and cr_items.item_id = $item_column"
	set cr_from "cr_items,"
    } else {
	# We don't need to search for attributes so we don't need to join
	# on the cr_items table. This should speed things up. This assumes
	# that packages other than contacts that add search condition
	# types do not need the revision_id column, and only needs the
	# party_id column. If this is not the case we may want to add a
	# callback here to check if another package needs the revisions 
	# table.
	#
	# If this needs to change you should also update the
	# contacts/lib/contacts.tcl file which behave the same way.
	set cr_where ""
	set cr_from ""
    }

    set results ""
#    if { [catch {
	set query [db_list select_${object_type} {}]
#    } errmsg] } {
#	ns_log Error "contact::search::results_count_not_cached contact search $search_id had a problem \n\n$errmsg"
#    }
    
    if { [exists_and_not_null query] } {
        set result ${party_id}
        if { $not_p } {
            append result " not"
        }
        append result " in ( [template::util::tcl_to_sql_list $query] )"
    } else {
        set result ""
    } 
    return $result
}


ad_proc -public contact::search_clause {
    {-and:boolean}
    {-search_id}
    {-query ""}
    {-party_id "acs_object.object_id"} 
    {-limit_type_p "1"}
} {
    Get the search clause for a search_id

    @param and Set this flag if you want the result to start with an 'and' if the list of where clauses returned is non-empty.
} {
    set query [string trim $query]
    set object_type [contact::search::object_type -search_id $search_id]
    
    set search_clauses [list]
    set where_clause [contact::search::where_clause -search_id $search_id -party_id $party_id -limit_type_p $limit_type_p]

    if { [exists_and_not_null where_clause] } {
        lappend search_clauses $where_clause
    }
    
    if { [exists_and_not_null query] } {
        lappend search_clauses [contact::search::query_clause -query $query -object_type $object_type]
    }

    set result {}
    if { [llength $search_clauses] > 0 } {
        if { $and_p } {
            append result "and "
        }
        if { [llength $search_clauses] > 1 } {
            append result "( [join $search_clauses "\n and "] )"
        } else {
            append result [join $search_clauses "\n and "]
        }
    }
    return $result
}


ad_proc -public contact::search_pretty {
    {-search_id}
    {-format "text/html"}
} {
    Get the search in human readable format. Cached
} {
    return [util_memoize [list ::contact::search_pretty_not_cached -search_id $search_id -format $format]]
}


ad_proc -public contact::search_pretty_not_cached {
    {-search_id}
    {-format "text/html"}
} {
    Get the search in human readable format
} {

    contact::search::get -search_id $search_id -array "search_info"
    
    if { $search_info(object_type) == "person" } {
	set object_type [_ intranet-contacts.people]
    } elseif { $search_info(object_type) == "organization" } {
	set object_type [_ intranet-contacts.organizations]
    } elseif { $search_info(object_type) == "employee" } {
	set object_type [_ intranet-contacts.employees]
    } else {
	set object_type [_ intranet-contacts.people_or_organizations]
    }
    
    # the reason we do not put this in the db_foreach statement is because we 
    # can run into problems with the number of database pools we have when a sub
    # query is a condition. We are limited to 3 levels of database access for most
    # openacs installs so this bypasses that problem
    set db_conditions [db_list_of_lists select_conditions {}]
    set conditions [list]
    foreach condition $db_conditions {
	lappend conditions [contacts::search::condition_type \
				-type [lindex $condition 0] \
				-request pretty \
				-var_list [lindex $condition 1] \
				-object_type $object_type
			   ]
    }

    if { [llength $conditions] > 0 } {


        set results "[_ intranet-contacts.Search_for_all_object_type_where]\n"

	if { $search_info(all_or_any) == "all" } {
	    append results [join $conditions "\n[_ intranet-contacts.and] "]
	} else {
	    append results [join $conditions "\n[_ intranet-contacts.or] "]
	}

	if { $format == "text/html" } { 
	    set results [ad_enhanced_text_to_html $results]
	} else {
	    set results [ad_enhanced_text_to_plain_text $results]
	}

	return $results
    } else {
	return {}
    }
}

ad_proc -public contact::search::query_clause {
    {-and:boolean}
    {-query ""}
    {-object_type}
} {
    create a contact search query. If the query supplied is an integer
    it searches for the party_id otherwise the search is for contacts
    that match all 

    @param and Set this flag if you want the result to start with an 'and' if the list of where clauses returned is non-empty.
    @param query Query to be searched for
    @param object_type Object Type, this will determine which fields will be searched for
} {
    # Clean up the query
    set query [string trim $query]
    regsub -all "'" $query "''" query

    set query_clauses [list]

    # Deal with callbacks
    set callback_query_clauses [callback contact::search::query_clauses -query $query -object_type $object_type]
	foreach callback_clauses $callback_query_clauses {
	    foreach clause $callback_clauses {
	        lappend query_clauses $clause
	    }
	}
    
    # Attributes to check for
    switch $object_type {
        person { set attribute_list [list persons.first_names persons.last_name parties.email]}
        im_company { set attribute_list [list im_companies.company_name]}
        im_office {set attribute_list [list im_offices.office_name]}
    }

	if { [string is integer $query] } {
	    lappend query_clauses "$object_id = $query"
	} elseif { $query ne "" } {		
		# We want to enable searches with "*", to select all users who's 
		# last_name starts with "Ab", searching for "Ab*"
		# For this we check if the term starts or ends with "*" and if yes
		# we do a regsub to replace the "*" with "%" for reuse in SQL
		if {[string length [string trim $query "*"]] == [string length $query]} {
		    set query "%${query}%"
		} else {
		    regsub -all {\*} $query "%" query
		}
		
	    # Now create the query_clauses for the terms
	    foreach attribute $attribute_list {
	        lappend query_clauses "lower($attribute) like lower('${query}')"
	    }
	}
    

    set result {}
    if { [llength $query_clauses] > 0 } {
        if { $and_p } {
            append result "and "
        }
        if { [llength $query_clauses] > 1 } {
            append result "( [join $query_clauses "\n or "] )"
        } else {
            append result [join $query_clauses "\n or "]
        }
    }
    return $result
}

ad_proc -public contact::search::condition::new {
    {-search_id}
    {-type}
    {-var_list}
} {
    create a contact search
} {
    if { [string is false [contact::search::condition::exists_p -search_id $search_id -type $type -var_list $var_list]] } {
        db_dml insert_condition {
            insert into contact_search_conditions
            ( condition_id, search_id, type, var_list )
            values 
            ( (select acs_object_id_seq.nextval), :search_id, :type, :var_list )
        }
    }
}


ad_proc -public contact::search::condition::delete {
    {-condition_id}
} {
    create a contact search
} {
    db_dml insert_condition {
        delete from contact_search_conditions where condition_id = :condition_id
    }
}

ad_proc -public contact::search::condition::exists_p {
    {-search_id}
    {-type}
    {-var_list}
} {
} {
    if { [db_0or1row exists_p { select 1 from contact_search_conditions where search_id = :search_id and type = :type and var_list = :var_list }] } {
        return 1
    } else {
        return 0
    }
}




ad_proc -public contact::search::where_clause {
    {-search_id}
    {-and:boolean}
    {-party_id}
    {-limit_type_p "1"}
} {
} {
    contact::search::permitted -search_id $search_id
    if { $and_p } {
        set results [util_memoize [list ::contact::search::where_clause_not_cached \
				       -search_id $search_id \
				       -and \
				       -party_id $party_id \
				       -limit_type_p $limit_type_p]]
    } else {
        set results [util_memoize [list ::contact::search::where_clause_not_cached \
				       -search_id $search_id \
				       -party_id $party_id \
				       -limit_type_p $limit_type_p]]
    }

    if { $results eq {} } {
	# we allow for the special case that somebody supplied a
	# list_id or group_id instead of a search_id
	if { [contact::list::exists_p -list_id $search_id] } {
	    if { [contact::owner_read_p -object_id $search_id -owner_id [ad_conn user_id]] } {
		# they can search for this list
		if { $and_p } {
		    append results " and "
		}
		append results " $party_id in ( select party_id from contact_list_members where list_id = $search_id ) "
	    }
	} elseif { [contact::group::mapped_p -group_id $search_id] } {
	    if { [permission::permission_p -object_id $search_id -party_id [ad_conn user_id] -privilege "read"] } {
		  # they can search for this group
		if { $and_p } {
		    append results " and "
		}
		append results " $party_id in ( select gamm${search_id}.member_id from group_approved_member_map gamm${search_id} where gamm${search_id}.group_id = $search_id ) "
	    }
	}
    }
    return $results
}

ad_proc -public contact::search::where_clause_not_cached {
    {-search_id}
    {-and:boolean}
    {-party_id}
    {-limit_type_p}
} {
} {
    db_0or1row get_search_info {}
    set where_clauses [list]

    if { [exists_and_not_null all_or_any] } {
	set result {}
	if { [string is true $limit_type_p] } {
	    if { $object_type == "person" } {
		append result "$party_id = persons.person_id\n"
	    } elseif { $object_type == "organization" } {
		append result "$party_id = organizations.organization_id\n"
	    }
	}
	# the reason we do not put this in the db_foreach statement is because we 
	# can run into problems with the number of database pools we have when a sub
	# query is a condition. We are limited to 3 levels of database access for most
	# openacs installs so this bypasses that problem
	set db_conditions [db_list_of_lists select_queries {}]
	foreach condition $db_conditions {
	    set type [lindex $condition 0]
	    lappend where_clauses [contacts::search::condition_type \
				       -type [lindex $condition 0] \
				       -request sql \
				       -var_list [lindex $condition 1] \
				       -object_type $object_type
				  ]
	}
	

	if { [llength $where_clauses] > 0 } {
	    if { $all_or_any == "any" } {
		set operator "or"
	    } else {
		set operator "and"
	    }
	    if { [exists_and_not_null result] } {
		append result " and "
	    }
	    if { [llength $where_clauses] > 1 } {
		append result "( [join $where_clauses "\n $operator "] )"
	    } else {
		append result [lindex $where_clauses 0]
	    }
	}
	if { [exists_and_not_null result] } {
	    set result "( $result )"
	    if { $and_p } {
	    set result "and $result"
	    }
	}
    } else {
        set result {}
    }

    return $result
}

ad_proc -public contact::search::object_type {
    {-search_id}
    {-default ""}
} {
    Return the object_type for a search
} {
    return [util_memoize [list contact::search::object_type_not_cached -search_id $search_id -default $default]]
}

ad_proc -public contact::search::object_type_not_cached {
    {-search_id}
    {-default}
} {
    return [db_string get_object_type "" -default $default]
}