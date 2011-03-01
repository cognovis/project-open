ad_library {

    These procs are there to ensure backwards compatibility for possible 
    API breakages. Once it is sure that an old proc interface is not used 
    anymore it should be removed from this file. Also move unused or 
    deprecated procs here so that we avoid cluttering up the other files.

    @author Dirk Gomez (openacs@dirkgomez.de)
    @creation-date Feb 19, 2004
    @cvs-id $Id: 
}

ad_proc -deprecated calendar_have_private_p { 
    {-return_id 0} 
    {-calendar_id_list {}}
    party_id 
} {
} {
    calendar::have_private_p -return_id $return_id -calendar_id_list $calendar_id_list $party_id
}

ad_proc -deprecated calendar_assign_permissions { calendar_id
                                      party_id
                                      cal_privilege
                                      {revoke ""}                        
} {
} {
    calendar::assign_permissions $calendar_id \
	$party_id \
	$cal_privilege \
	$revoke
}

ad_proc -deprecated calendar_create { owner_id
                          private_p          
                          {calendar_name ""}       
} {
} {
    calendar_create $owner_id $private_p $calendar_name
}

ad_proc -deprecated calendar_make_datetime {
    event_date
    {event_time ""}
} {
    given a date, and a time, construct the proper date string
    to be imported into oracle. (yyyy-mm-dd hh24:mi format)s
} {
    calendar::make_datetime $event_date $event_time
}
