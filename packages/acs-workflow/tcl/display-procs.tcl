ad_library {
    Procs to render workflow information in HTML.

    @author Lars Pind (lars@pinds.com)
    @creation-date 18 July 2000
    @cvs-id $Id$
}


ad_proc wf_if_null { string value_if_null } {
    If string is emtpy, returns <code>value_if_null</code>, otherwise returns string.
    @author Lars Pind
    @creation-date 27 September 2000
} {
    if { [empty_string_p $string] } {
	return $value_if_null
    } else {
	return $string
    }
}

ad_proc wf_attribute_widget {
    {-name ""}
    attribute_info
} {
    Returns an HTML fragment containing a form element for entering the value of an attribute.
    <p>
    This problem should eventually be solved completely by the templating subsystem.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 10 July, 2000
} {
    array set attribute $attribute_info
    
    if { [empty_string_p $name] } {
	set name "attributes.$attribute(attribute_name)"
    }

    # The default widget
    set widget "<input type=text name=\"$name\">"

    switch $attribute(datatype) {
	boolean {
	    #set widget "<select name=\"$name\"><option value=\"-\">--Please select--</option><option value=\"t\">#acs-kernel.common_Yes#</option><option value=\"f\">#acs-kernel.common_No#</option></select>"
	    set widget "<select name=\"$name\"><option value=\"t\" [ad_decode $attribute(value) "t" "SELECTED" ""]>#acs-kernel.common_Yes#</option><option value=\"f\" [ad_decode $attribute(value) f SELECTED ""]>#acs-kernel.common_No#</option></select>"

	}
	number {
	    switch $attribute(wf_datatype) {
		party {
		    set widget "<select name=\"$name\">"
		    db_foreach party_with_at_least_one_member {
			select p.party_id, 
			       acs_object.name(p.party_id) as name, 
			       decode(p.email, '', '', '('||p.email||')') as email
			from   parties p
			where  0 < (select count(*)
                                    from   users u, 
                                           party_approved_member_map m
			            where  m.party_id = p.party_id
			            and    u.user_id = m.member_id)
		    } {
			append widget "<option value=\"$party_id\">$name $email</option>"
		    }
		    append widget "</select>"
		}
	    }
	}
    }
    return $widget
}



ad_proc wf_attribute_value_pretty {
    attribute_info
} {
    Returns a nice display version of the value of an attribute. 
    Specifically, it displays booleans as "#acs-kernel.common_Yes#" or "#acs-kernel.common_No#", and it 
    displays a party with the <a
    href="/api-doc/proc-view?proc=ad_present_user"><code>ad_present_user</code></a>
    function.
    <p>
    This is a kludge until the general ACS templating effort settles down.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 10 July, 2000
} {
    array set attribute $attribute_info

    set value $attribute(value)
    switch $attribute(datatype) {
	boolean {
	    set value [ad_decode $value "t" "#acs-kernel.common_Yes#" "#acs-kernel.common_No#"]
	}
    }
    return $value
}





ad_proc wf_assignment_widget {
    {-name ""}
    -case_id
    role_key
} {
    Returns an HTML fragment containing a form element for entering the value of an attribute.
    <p>
    This problem should eventually be solved completely by the templating subsystem.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 10 July, 2000
} {
    if { [empty_string_p $name] } {
	set name "assignments.$role_key"
    }

    if { [info exists case_id] && ![empty_string_p $case_id] } {
	set current_assignments [db_list assignment_select "
		select	ca.party_id
		from	wf_case_assignments ca, 
			wf_cases c
		where	c.case_id = :case_id
			and ca.role_key = :role_key
			and ca.workflow_key = c.workflow_key
		order by party_id
	"]  
    } else {
	set current_assignments {}
    }

    set widget "<select name=\"$name\" multiple size=10>"
    db_foreach party_with_at_least_one_member {
	select	p.party_id, 
   		acs_object.name(p.party_id) as name, 
 		decode(p.email, '', '', '('||p.email||')') as email
	from	parties p
	where	0 < (select count(*)
  	            from   users u, 
	            party_approved_member_map m
	            where  m.party_id = p.party_id
	            and    u.user_id = m.member_id
		)
    } {
	append widget "<option value=\"$party_id\" [ad_decode [lsearch -exact $current_assignments $party_id] -1 "" "selected"]>$name $email</option>"
    }
    append widget "</select>"
    
    return $widget
}
