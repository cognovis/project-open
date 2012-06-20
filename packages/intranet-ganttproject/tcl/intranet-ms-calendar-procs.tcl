# /packages/intranet-ganttproject/tcl/intranet-ms-calendar-procs.tcl
#
# Copyright (C) 12 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Functionality around MS-Project calendars
    @author frank.bergmann@project-open.com
}


# ------------------------------------------------------------------
# Operations on MS-Calendar
# ------------------------------------------------------------------

namespace eval im_ms_calendar {

ad_proc -public default {
    {-start_hour1 ""}
    {-end_hour1 ""}
    {-start_hour2 ""}
    {-end_hour2 ""}
} {
    Returns the default calendar in ]po[
} {
    if {"" == $start_hour1} { set start_hour1 [parameter::get_from_package_key -package_key "intranet-ganttproject" -parameter CalendarStartHour1 -default "09:00:00"] }
    if {"" == $end_hour1  } { set end_hour1   [parameter::get_from_package_key -package_key "intranet-ganttproject" -parameter CalendarEndHour1   -default "13:00:00"] }
    if {"" == $start_hour2} { set start_hour2 [parameter::get_from_package_key -package_key "intranet-ganttproject" -parameter CalendarStartHour2 -default "15:00:00"] }
    if {"" == $end_hour2  } { set end_hour2   [parameter::get_from_package_key -package_key "intranet-ganttproject" -parameter CalendarEndHour2   -default "19:00:00"] }

    set working_times [list]
    lappend working_times [list $start_hour1 $end_hour1]
    lappend working_times [list $start_hour2 $end_hour2]

    set day [list day_working 1 working_times $working_times]

    set hash(1) [list day_working 0]
    set hash(2) $day
    set hash(3) $day
    set hash(4) $day
    set hash(5) $day
    set hash(6) $day
    set hash(7) [list day_working 0]

    return [array get hash]
}

ad_proc -public from_xml {
    calendar_node
} {
    Parses a piece of XML and returns the ]po[ internal representation of a calendar
} {
    ns_log Notice "im_ms_calendar::from_xml:"

    set calendar_uid ""
    set calendar_name ""
    set calendar_is_base ""
    set calendar_base_uid ""
    array set hash {}
    foreach calendar_attr [$calendar_node childNodes] {
	set node_name [string tolower [$calendar_attr nodeName]]
	set node_text [$calendar_attr text]
	switch $node_name {
	    uid			{ set calendar_uid $node_text }
	    name		{ set calendar_name $node_text }
	    isbasecalendar	{ set calendar_is_base $node_text }
	    basecalendaruid	{ set calendar_base_uid $node_text }
	    weekdays		{
		set workingtimes ""
		foreach week_days_attr [$calendar_attr childNodes] {
		    set node_name [string tolower [$week_days_attr nodeName]]
		    set node_text [$week_days_attr text]
		    switch $node_name {
			weekday		{
			    set day_type ""
			    set day_working ""
			    set working_times {}
			    foreach week_day_attr [$week_days_attr childNodes] {
				set node_name [string tolower [$week_day_attr nodeName]]
				set node_text [$week_day_attr text]
				ns_log Notice "im_ms_calendar::from_xml: calendar/weekdays/weekday: node_name=$node_name, node_text=$node_text"
				switch $node_name {
				    daytype		{ set day_type $node_text  }
				    dayworking		{ set day_working $node_text  }
				    workingtimes {
					foreach working_times_attr [$week_day_attr childNodes] {
					    set node_name [string tolower [$working_times_attr nodeName]]
					    set node_text [$working_times_attr text]
					    ns_log Notice "im_ms_calendar::from_xml: calendar/weekdays/weekday/workingtimes/: node_name=$node_name, node_text=$node_text"
					    switch $node_name {
						workingtime		{
						    set from_time ""
						    set to_time ""
						    foreach working_time_attr [$working_times_attr childNodes] {
							set node_name [string tolower [$working_time_attr nodeName]]
							set node_text [$working_time_attr text]
							ns_log Notice "im_ms_calendar::from_xml: calendar/weekdays/weekday/workingtimes/workingtime/: node_name=$node_name, node_text=$node_text"
							switch $node_name {
							    fromtime		{ set from_time $node_text  }
							    totime		{ set to_time $node_text  }
							}
						    }
						    if {"" != $from_time && "" != $to_time} {
							lappend working_times [list $from_time $to_time]
						    }
						}
					    }
					}
				    }
				}
			    }
			    if {"" != $day_type} {
				set hash($day_type) [list day_working $day_working working_times $working_times]
			    }
			}
		    }
		}
	    }
	}
    }
    ns_log Notice "im_ms_calendar::from_xml: calendar_name=$calendar_name, [array get hash]"


    set calendar_hash(uid) $calendar_uid
    set calendar_hash(name) $calendar_name
    set calendar_hash(is_base_calendar) $calendar_is_base
    set calender_hash(base_calendar_uid) $calendar_base_uid
    set calendar_hash(week_days) [array get hash]

    return [array get calendar_hash]
}

ad_proc -public to_xml {
    {-tab_level 1}
    {-calendar_uid 1}
    {-calendar_name "Standard"}
    -calendar
} {
    Converts the specified calendar to XML
} {
    set tabs ""
    for {set i 0} {$i < $tab_level} {incr i} { append tabs "\t" }

    array set hash $calendar
    set week_days_xml ""
    for {set d 1} {$d < 7} {incr d} { 

	# Extract the parameters from the hash
	set day_list ""
	if {[info exists $hash($d)]} { set day_list $hash($d) }
	array unset day_hash
	array set day_hash $day_list
	set day_working 0
	set working_time {}
	if {[info exists day_hash(day_working)]} { set day_working $day_hash(day_working) }
	if {[info exists day_hash(working_time)]} { set working_time $day_hash(working_time) }

	set xml "
$tabs		<WeekDay>
$tabs			<DayType>$d</DayType>
$tabs			<DayWorking>$day_working</DayWorking>\n"

	if {$day_working} {
	    foreach tuple $working_time {
		set start_time [lindex $tuple 0]
		set end_time [lindex $tuple 1]
		append xml "
$tabs				<WorkingTime>
$tabs					<FromTime>$start_time</FromTime>
$tabs					<ToTime>$end_time</ToTime>
$tabs				</WorkingTime>
"
	    }
	}
	append xml "$tabs		</WeekDay>"
	append week_days_xml $xml
    }

    return "\
$tabs<Calendar>
$tabs	<UID>$calendar_uid</UID>
$tabs	<Name>$calendar_name</Name>
$tabs	<IsBaseCalendar>1</IsBaseCalendar>
$tabs	<BaseCalendarUID>-1</BaseCalendarUID>
$tabs	<WeekDays>$week_days_xml
$tabs	</WeekDays>
$tabs</Calendar>
"

}




# ----------------------------------------------------------------------
#
# ----------------------------------------------------------------------


}