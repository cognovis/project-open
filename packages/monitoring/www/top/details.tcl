# /www/admin/monitoring/top/details.tcl

ad_page_contract {
    Reports details from saved top statistics

    @author sklein@arsdigita.com 
    @cvs-id $Id: details.tcl,v 1.1.1.2 2006/08/24 14:41:42 alessandrol Exp $

    @param  n_days        the # of days over which to average data 
    @param  start_time    start time on a given day
    @param  end_time      end time on a given day
    @param  orderby       the field by which to order the proc_avg data
    @param  orderbysystem field by which to order the system_avg data
    @param  showtop       show the top of the moment? (boolean)
    @param  key           the field on which to search for details; for a switch
    @param  value         the value to search for in the key field
    @param  showall       a boolean for sticklers.  for now, always "f"
} {
    {n_days 3}
    {start_time {0}}
    {end_time {24}}
    {orderby       {cpu_pct}}
    {orderbysystem {day}}
    {showtop {f}}
    {showall {f}}
    {key {command}}
    {value {oracle}}
    {min_cpu_pct {20}}
}

set title "DETAILS"
set context [list "DETAILS"]


# Notes:  Some of the queries here were taking a long time,
#   so I stuck in ns_writes to write out each table
#   as it is generated. 

# KS - I got rid of this.  Add in doc_body_flush with new document api
#      to restore this behavior

# the key parameter must correspond to one of these column names 
# on the ad_monitoring_top table
if { [lsearch -exact [list command username pid hour day] $key] == -1 } {
    ad_return_complaint 1 "Valid values for the key parameter are: 
    list, command, username, pid, hour, or day"
    return
}

### Define table definitions for ad_table

set top_system_avg_table_def {
    {time  "hour" {} \
        {<td><a href="details?key=hour&value=[ns_urlencode $time]">$time</a></td>}}
    {load_average "load" {} {}}
    {memory_free_average "free mem" {} \
        {<td>[ad_monitor_format_kb $memory_free_average]</td>}}
    {memory_swap_free_average "free swap" {} \
        {<td>[ad_monitor_format_kb $memory_swap_free_average]</td>}}
    {memory_swap_in_use_average "used swap" {} \
        {<td>[ad_monitor_format_kb $memory_swap_in_use_average]</td>}}
    {count "count" {} {}}
}  

set top_system_table_def {
    {time  "time" {} {}}
    {load_average "load" {} {}}
    {memory_free_average "free mem" {} \
        {<td>[ad_monitor_format_kb $memory_free_average]</td>}}
    {memory_swap_free_average "free swap" {} \
        {<td>[ad_monitor_format_kb $memory_swap_free_average]</td>}}
    {memory_swap_in_use_average "used swap" {} \
        {<td>[ad_monitor_format_kb $memory_swap_in_use_average]</td>}}
}   

set top_proc_table_def {
    {time "Time" {} {}}
    {threads "Thr" {} {}}
    {command "Command" {} \
        {<td align=right><a href="details?key=command&value=[ns_urlencode $command]">$command</a></td>}}
    {username "Username" {} \
        {<td><a href="details?key=username&value=$username">$username</a></td>}}
    {pid "PID" {} \
        {<td><a href="details?key=pid&value=$pid">$pid</a></td>}}
    {cpu_pct "CPU" {} {}}
    {count "Cnt" {} {}}
}  

#### Set up sql for the rest of the page

# here are all the bind variables needed by both queries
set bind_vars [ad_tcl_vars_to_ns_set start_time end_time min_cpu_pct n_days value]

##
## 1. Create the sql to filter by date, time, and detailed query

if { [string compare $key "day"] } {
    # we're looking at a specific day
    set n_days "all"
}
if { ![string equal $key "hour"] } {
    set time_clause [db_map time_clause_1]
    
    if { [string compare $n_days "all"] != 0 } {
        # Need to multiply n_days by ($end_time-to_char(sysdate,'HH24'))/24 
        # for accurate current snapshots.  That is, displaying back in time
        # needs to be relative to the selected end_time, not to sysdate.
        set current_hour [db_string mon_current_hour { *SQL* } ]

        if { $end_time > $current_hour } {
            # we correct for the last day in the query if the end time
            # is later than the current time.
            # TODO: need to add this into the query?
            set hour_correction [db_map hour_correction]
        } else {
            set hour_correction ""
        }
    }
} else { 
    # we're looking at a specific hour of a specific day, no need to filter
    set time_clause "where 1 = 1" 
}

### 2. Create the sql to fill the ad_tables, given the detailed constraint.
##
set proc_group_by "to_char(timestamp, 'MM/DD HH24')"
set proc_time_sql "to_char(timestamp, 'MM/DD HH24') || ':00' as time"

switch $key {
    day  { 
        set details_clause "to_char(timestamp, 'Mon DD') = :value"  
        set system_time_sql  "to_char(timestamp, 'MM/DD HH24') || ':00' as time"
        set system_group_by  "to_char(timestamp, 'MM/DD HH24')"
    }
    hour { 
        set details_clause  "to_char(timestamp, 'MM/DD HH24') || ':00' = :value"
        set system_time_sql "to_char(timestamp, 'MM/DD HH24:MI') as time"
        set system_group_by "timestamp"
        # if you want to show every single proc:
        if {[string match $showall "t"]} {
            set proc_time_sql "to_char(timestamp, 'MM/DD HH24:MI') as time"
            set proc_group_by "timestamp"
        }      
    }
    default { 
        set details_clause "$key = :value"
        set proc_time_sql "to_char(timestamp, 'MM/DD HH24:MI') as time"
        set proc_group_by "timestamp"
    }
}

## the $xxx_time_sql selects the appropriate quantity as 'time',
## the $details_clause specifies which day or hour to focus on, and
## the $xxx_group_by clause groups either by hour or by second
## (i.e., not at all).  

set proc_query [db_map proc_query]

if { [string match $key "hour"] || [string match $key "day"] } {
    set load_and_memory_averages_sql [db_map load_and_memory_averages_sql]

    set system_query [db_map system_query]
}

### Begin returning the page.
append page_content "
 
   <h2>Statistics from Top</h2>
 
<table width=100%>
 <tr><td align=right>
   <a href=index?[export_url_vars n_days start_time end_time orderby]> 
          return to index</a> 
 </tr>
</table>
"

set n_days_list [list]
foreach n [list 1 2 3 7 14 31 all] {
    if { $n == $n_days } {
        lappend n_days_list "<b>$n</b>"
    } else {
        lappend n_days_list "<a href=details?n_days=$n&[export_url_vars\
                           key value start_time end_time orderby orderbysystem min_cpu_pct]>$n</a>"
    }
}

set start_select ""
set end_select ""
for { set i 0 } { $i < 25 } { incr i } {
    if { $i == 0 || $i == 24} { 
        set text "Midnight"
    } elseif { $i == 12 } { 
        set text "Noon"
    } elseif { $i > 12 } {  
        set text "[expr {$i - 12}] pm"
    } else {                
        set text "$i am"
    }

    append start_select " <option value=\"$i\"[if {$i == $start_time} {
           set foo " selected"}]> $text\n"

    append end_select   " <option value=\"$i\"[if {$i == $end_time} {
           set foo " selected"}]> $text\n"
}

set cpu_select ""
foreach percent {0.5 0.1 0.01 0 1 2 5 10 20 30 40 50 75} {
    append cpu_select " <option value=\"$percent\"[if {$percent == $min_cpu_pct} {
    set foo " selected"}]> $percent%\n"
}

# This form only includes the time-selection drop-down menus,
# so we quietly pass in the other important variables.  Also,
# the rest of the pageis slow, so we ns_write the top section.
append page_content "<form method=get action=details>
                  [export_form_vars n_days key value orderby orderbysystem]
<table cellspacing=1 width=70%>
<tr>
  <td colspan=3> <blockquote> Select the time of day during which you wish 
     to monitor system information, and the number of days over which you wish 
     to calculate any averages.</blockquote> </td>
</tr>
<tr bgcolor=cccccc>
  <th>Number of days</th>  <th>Start time - End time</th>  <th>Min CPU %</th>
</tr>
<tr>
  <td valign=top align=center>[join $n_days_list " | "]</td>
  <td valign=top align=center>
      <select name=start_time>$start_select</select> - 
         <select name=end_time>$end_select</select>
  <td valign=top align=center>
      <select name=min_cpu_pct>$cpu_select</select>
      <input type=submit value=Go>
  </td>
</tr>
</table>
</form>
"

set top_location [ad_parameter -package_id [monitoring_pkg_id] TopLocation monitoring "/usr/local/bin/top"] 

if { [string match $showtop "t"] } {
    if [catch { set top_output [exec $top_location] } errmsg] {
        # couldn't exec top at TopLocation
        if { ![file exists $top_location] } {
            ad_return_error "top not found" "
            The top procedure could not be found at $top_location:
            <blockquote><pre> $errmsg </pre></blockquote>"
            return
        }

        ad_return_error "insufficient top permissions" "
        The top procedure at $top_location cannot be run:
        <blockquote><pre> $errmsg </pre></blockquote>"
        return
    }
    # top execution went ok
    append page_content "<h4>Current top output on this machine</h4>
    <pre>$top_output</pre>
    "
    #doc_return 200 text/html $page_content
    return
}

set number_rows [db_string mon_top_entries { *SQL* } ]

if { $number_rows == 0 } {
    append page_content "
       <b> No data match the given criteria  </b>
         <ul>
         <li>time clause : <font size=-1>$time_clause</font>;
         <li>details : <font size=-1>$details_clause</font> 
     <li>over the past $n_days days
    </ul>
       "
    #doc_return 200 text/html $page_content
    return
} else {  
    append page_content "<h4> Details for the $value $key </h4> \n " 
}

# we include a "system" suffix in this call to ad_table to use 
# the right orderby variable
if { [string match $key "hour"] } {
    append page_content "[ad_table -Tsuffix system -bind $bind_vars \
        unused $system_query $top_system_table_def]
      <hr width=70%>
    "
} elseif { [string match $key "day"] } {
    append page_content "[ad_table -Tsuffix system -bind $bind_vars \
        unused $system_query $top_system_avg_table_def]
      <hr width=70%>
    "
}

append page_content "[ad_table -bind $bind_vars \
    unused $proc_query $top_proc_table_def] <p> 

</table>"

# doc_return 200 text/html $page_content

