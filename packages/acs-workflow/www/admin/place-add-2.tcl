ad_page_contract {
    Add place.
} {
    workflow_key:notnull
    place_name:notnull
    {sort_order:integer ""}
    {special ""}
} -validate {
    place_name_unique -requires { workflow_key:notnull place_name:notnull } {
	set num_rows [db_string num_places {
	    select count(*) 
	    from   wf_places
	    where  workflow_key = :workflow_key
	    and    place_name = :place_name
	}]

        if { $num_rows > 0 } {
	    ad_complain "There is already a place with this name"
	}
    }

    trigger_type_legal -requires { trigger_type } {
	set trigger_type [string tolower $trigger_type]
	if { [lsearch -exact { user automatic message time } $trigger_type] == -1 } {
	    ad_complain "Trigger type must be one of user, automatic, message or time."
	}
    }

    special_is_start_or_end_or_blank -requires { special } {
	set special [string tolower $special]
	if { ![empty_string_p $special] && \
		![string equal $special "start"] && \
		![string equal $special "end"] } {
	    ad_complain "'Special' must be 'start', 'end', or the empty string."
	}
    }

    special_is_not_taken -requires { special_is_start_or_end_or_blank } {
	if { ![empty_string_p $special] } {
	    set num_rows [db_string num_places { 
		select decode(count(*),0,0,1) 
		from wf_places
		where workflow_key = :workflow_key
		and place_key = :special
	    }]
   	    if { $num_rows > 0 } {
		ad_complain "This process already has a[ad_decode $special "end" "n" ""] $special place."
	    }
	}
    }
}

if { ![empty_string_p $special] } {
    set place_key $special
} else {
    set place_key [wf_make_unique -maxlen 100 \
	    -taken_names [db_list place_keys {select place_key from wf_places where workflow_key = :workflow_key}] \
	    [wf_name_to_key $place_name]]
}

db_dml place_add {
    insert into wf_places (place_key, place_name, workflow_key)
    values (:place_key, :place_name, :workflow_key)
}
    
wf_workflow_changed $workflow_key

ad_returnredirect "define?[export_url_vars workflow_key place_key]"


