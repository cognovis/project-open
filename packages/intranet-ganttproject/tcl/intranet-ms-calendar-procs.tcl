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
	if {[info exists hash($d)]} { set day_list $hash($d) }

	array unset day_hash
	array set day_hash $day_list

	set day_working 0
	set working_times {}
	if {[info exists day_hash(day_working)]} { set day_working $day_hash(day_working) }
	if {[info exists day_hash(working_times)]} { set working_times $day_hash(working_times) }

	set xml "
$tabs		<WeekDay>
$tabs			<DayType>$d</DayType>
$tabs			<DayWorking>$day_working</DayWorking>\n"

	if {$day_working} {
	    append xml "<WorkingTimes>\n"
	    foreach tuple $working_times {
		set start_time [lindex $tuple 0]
		set end_time [lindex $tuple 1]
		append xml "\
$tabs				<WorkingTime>
$tabs					<FromTime>$start_time</FromTime>
$tabs					<ToTime>$end_time</ToTime>
$tabs				</WorkingTime>
"
	    }
	    append xml "</WorkingTimes>\n"
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



ad_proc -public seconds_in_interval {
    -start_date:required
    -end_date:required
    -calendar:required
} {
    Returns the number of workable seconds between
    start_date and end_date, according to the specified
    calendar
} {
    ns_log Notice "im_ms_calendar::seconds_in_interval: start=$start_date, end=$end_date, calendar=$calendar"
    if {"" == $start_date} { error "im_ms_calendar::seconds_in_interval: start_date is empty" }
    if {"" == $end_date} { error "im_ms_calendar::seconds_in_interval: end_date is empty" }

    # cal_hash maps day_of_week {1..7} into a list of service hour intervals {{09:00:00 13:00:00} {15:00:00 19:00:00}}
    array set cal_hash $calendar

    set start_julian [im_date_ansi_to_julian [string range $start_date 0 9]]
    set end_julian [im_date_ansi_to_julian [string range $end_date 0 9]]
    set start_epoch [im_date_ansi_to_epoch $start_date]
    set end_epoch [im_date_ansi_to_epoch $end_date]

    set working_seconds 0
    ns_log Notice "im_ms_calendar::seconds_in_interval: start_julian=$start_julian, end_julian=$end_julian"
    for {set j $start_julian} {$j <= $end_julian} {incr j} {

	# ----------------------------------------------------------------------------------------
	# Get the service hours per Day Of Week (1=Su, 2=Mo, 7=Sa)
	# service_hours are like {09:00 18:00}
	set dow [expr 1 + (($j + 1) % 7)]
	set cal_day_string $cal_hash($dow)
	array unset cal_day_hash
	array set cal_day_hash $cal_day_string
	set service_hour_list {}
	if {[info exists cal_day_hash(working_times)]} { set service_hour_list $cal_day_hash(working_times) }
	ns_log Notice "im_ms_calendar::seconds_in_interval: j=$j, dow=$dow, working_seconds=$working_seconds, hours=$service_hour_list"

	set j_epoch [im_date_julian_to_epoch $j]
	set j_ansi [im_date_julian_to_ansi $j]
	foreach tuple $service_hour_list {
	    set hour_start_ansi "$j_ansi [lindex $tuple 0]"
	    set hour_end_ansi "$j_ansi [lindex $tuple 1]"
	    set hour_start_epoch [im_date_ansi_to_epoch $hour_start_ansi]
	    set hour_end_epoch [im_date_ansi_to_epoch $hour_end_ansi]

	    # Check that the working time is withing the start-end range specified in the parameters.
	    if {$hour_start_epoch < $start_epoch} { set hour_start_epoch $start_epoch }
	    if {$hour_end_epoch > $end_epoch} { set hour_end_epoch $end_epoch }

	    # Add the duration of the interval to the working seconds
	    if {$hour_end_epoch > $hour_start_epoch} {
		set working_seconds [expr $working_seconds + ($hour_end_epoch - $hour_start_epoch)]
	    }

	    ns_log Notice "im_ms_calendar::seconds_in_interval: j=$j, dow=$dow, hour_start_ansi=$hour_start_ansi, hour_end_ansi=$hour_end_ansi, hour_start_epoch=$hour_start_epoch, hour_end_epoch=$hour_end_epoch"
	}
    }
    return $working_seconds
}


# ----------------------------------------------------------------------
#
# ----------------------------------------------------------------------


}