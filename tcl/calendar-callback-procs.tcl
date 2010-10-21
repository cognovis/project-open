ad_library {
    Callbacks for the search package.

    @author Dirk Gomez <openacs@dirkgomez.de>
    @creation-date 2005-06-12
    @cvs-id $Id$
}

ad_proc -callback merge::MergeShowUserInfo -impl calendar {
    -user_id:required
} {
    Shows the calendar tables user info
} {
    set msg "Calendars of user_id: $user_id"
    set return_msg [list $msg]
    
    set cals [db_list get_calendars {*SQL*} ]
    if { [empty_string_p $cals ] } {
	lappend return_msg "none"
    } else {
	lappend return_msg $cals
    }
    
    return $return_msg
}

ad_proc -callback merge::MergePackageUser -impl calendar {
    -from_user_id:required
    -to_user_id:required
} {
    Merge the calendars of two users.
    The from_user_id is the user_id of the user
    that will be deleted and all the calendar elements
    of this user will be mapped to the to_user_id.
} {
    set msg "Merging calendar"
    ns_log Notice $msg
    set return_msg [list $msg]
    
    set from_calendars [db_list_of_lists get_from_calendars {*SQL*} ]
    db_transaction {
	ns_log Notice "  Entering to calendar transaction"
	foreach calendar $from_calendars {
	    # l_* vars will represent
	    # each item of the from_user_id list of lists
	    set l_cal_id [lindex $calendar 0]
	    set l_pkg_id [lindex $calendar 1]
	    
	    # if the pkg_id of this cal_id is the
	    # the same for some to_user_id cal
	    # we have to delete it, else we must 
	    # change the items from one cal to the other one
	    if { [db_string get_repeated_pkgs {*SQL*} ] } {
		# We will move the cal items if the 
		# calendars are of the same type (package_id)
		set to_cal_id [db_string gettocalid {*SQL*} ]
		
		db_dml calendar_items_upd { *SQL* }
		
		# ns_log Notice "  Deleting calendar"
		# TODO: calendar::delete -calendar_id $l_cal_i is broken
		# so, we will delete directly from the calendars table
		db_dml del_from_cal { *SQL* }
		
	    } else {
		ns_log Notice "  Change owner of $calendar"
		# change the owner
		db_dml calendars_upd { *SQL* }
	    }
	}
	set msg "  Calendar merge is done"
	ns_log Notice $msg
	lappend return_msg $msg
    }
    # I commented this section to avoid partial merges
    # If something is wrong the merge should be stopped.
    #        on_error {
    # 	    set msg "  I couldn't merge calendar. The error was $errmsg"
    # 	    ns_log Notice $msg
    # 	    lappend return_msg $msg
    # 	}
    return $return_msg
}
