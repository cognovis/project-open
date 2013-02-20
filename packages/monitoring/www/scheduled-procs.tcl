# /admin/monitoring/scheduled-procs.tcl

ad_page_contract {
    Displays a list of scheduled procedures.

    @author Jon Salz (jsalz@mit.edu)
    @cvs-id $Id: scheduled-procs.tcl,v 1.1.1.2 2006/08/24 14:41:39 alessandrol Exp $
} {
}


set title "Scheduled Procedures"
set context [list "$title"]

set page_content "

<form>

<h2>Scheduled Procedures on [ad_system_name]</h2>


<table>
<tr>
<th align=left bgcolor=#C0C0C0>Proc</th>
<th align=left bgcolor=#C0C0C0>Args</th>
<th align=right bgcolor=#C0C0C0>Count</th>
<th align=left bgcolor=#C0C0C0>Last Run</th>
<th align=left bgcolor=#C0C0C0>Next Run</th>
<th align=right bgcolor=#C0C0C0>Next Run In</th>
<th align=left bgcolor=#C0C0C0>Thread?</th>
<th align=left bgcolor=#C0C0C0>Once?</th>
<th align=left bgcolor=#C0C0C0>Debug?</th>
</tr>
"

set time_fmt "%m-%d %T"

set counter 0
set bgcolors { white #E0E0E0 }

proc ad_scheduled_procs_nextrun { interval last_run } {
    #  if simple ns_schedule_proc, interval will be integer
    #  if ns_schedule_daily, interval will be "hour" and "min" of next run
    #  if ns_schedule_weekly, interval will be "day", "hour" and "min"

    if { [llength $interval] == 1 } {
        set next_run [expr { $last_run + $interval }]
    } elseif { [llength $interval] == 2 } {
        set hour [lindex $interval 0]
        set minute [lindex $interval 1]

        set next_run [clock scan "${hour}:${minute}"]
        
        # has it already run today? Then get tomorrow's value
        if { [clock seconds] > $next_run } {
            set next_run [expr $next_run + 86400]
        }
    } elseif { [llength $interval] == 3 } {
        set day_num [lindex $interval 0]
        switch $day_num {
            0 { set day "Sunday" }
            1 { set day "Monday" }
            2 { set day "Tuesday" }
            3 { set day "Wednesday" }
            4 { set day "Thursday" }
            5 { set day "Friday" }
            6 { set day "Saturday" }
        }
        set hour [lindex $interval 1]
        set minute [lindex $interval 2]
        set next_run [clock scan "$day ${hour}:${minute}"]

        # has it already run this week? Then get next week's value
        if { [clock seconds] > $next_run } {
            set next_run [expr $next_run + 604800]
        }
    } else {
        ad_return_error "Error: Unknown interval" \
            "Error in monitoring/www/scheduled-procs.tcl : 
             ad_scheduled_procs_nextrun"
    }

    return $next_run
}

proc ad_scheduled_procs_compare { a b } {
    # compare based on when next run is scheduled
    set next_run_a [ad_scheduled_procs_nextrun [lindex $a 2] [lindex $a 5]]
    set next_run_b [ad_scheduled_procs_nextrun [lindex $b 2] [lindex $b 5]]

    if { $next_run_a < $next_run_b } {
        return -1
    } elseif { $next_run_a > $next_run_b } {
        return 1
    } else {
        return [string compare [lindex $a 3] [lindex $b 3]]
    }
}

foreach proc_info [lsort -command ad_scheduled_procs_compare [nsv_get ad_procs .]] {
    set bgcolor [lindex $bgcolors [expr { $counter % [llength $bgcolors] }]]
    incr counter

    set thread [ad_decode [lindex $proc_info 0] "t" "Yes" "No"]
    set once [ad_decode [lindex $proc_info 1] "t" "Yes" "No"]
    set interval [lindex $proc_info 2]
    set proc [lindex $proc_info 3]
    set args [lindex $proc_info 4]
    if { $args == "" } {
        set args "&nbsp;"
    }
    set time [lindex $proc_info 5]
    set count [lindex $proc_info 6]
    set debug [ad_decode [lindex $proc_info 7] "t" "Yes" "No"]
    set last_run [ad_decode $count 0 "&nbsp;" [ns_fmttime $time $time_fmt]]
    set next_run [ns_fmttime [ad_scheduled_procs_nextrun $interval $time] $time_fmt]
    set next_run_in "[expr { [ad_scheduled_procs_nextrun $interval $time] - [ns_time] }] s"

    append page_content "<tr>"
    foreach name { proc args } {
        append page_content "<td bgcolor=$bgcolor>[set $name]</td>"
    }
    append page_content "<td bgcolor=$bgcolor align=right>$count</td>"
    foreach name { last_run next_run } {
        append page_content "<td bgcolor=$bgcolor>[set $name]</td>"
    }
    append page_content "<td bgcolor=$bgcolor align=right>$next_run_in</td>"
    foreach name { thread once debug } {
        append page_content "<td bgcolor=$bgcolor>[set $name]</td>"
    }
    append page_content "</tr>\n"
}

append page_content "</table>


"

# doc_return 200 text/html $page_content
