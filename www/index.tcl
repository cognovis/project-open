ad_page_contract {
  present usage statistics, active users, etc

  @author Gustaf Neumann
  @cvs-id $Id$
} -query {
  {jsGraph 1}
} -properties {
  title:onevalue
  context:onevalue
  active_users_10
  current_system_activity
  current_load
  current_response
  views_trend
  users_trend
  response_trend
  throttle_stats
}

set title "Performance statistics"

# compute the average of the last n values (or less, if
# not enough values are given)
proc avg_last_n {list n var} {
  upvar $var cnt
  set total 0.0
  set list [lrange $list end-[incr n -1] end]
  foreach d $list { set total [expr {$total+$d}] }
  set cnt [llength $list]
  return [expr {$cnt > 0 ? $total*0.001/$cnt : 0}]
}


# collect current system statistics
proc currentSystemLoad {} {
  #    if {[catch {return [exec "/usr/bin/uptime"]}]} {
  #	return ""
  #    }
  set procloadavg /proc/loadavg
  if {[file readable $procloadavg]} {
    set f [open $procloadavg]; set c [read $f]; close $f
    return $c
  }
  return [exec /usr/bin/uptime]
}

# collect current response time (per minute and hour)
proc currentResponseTime {} {
  set tm [throttle trend response_time_minutes]
  set hours [throttle trend response_time_hours]
  if { $tm eq "" } { 
    set ::server_running "seconds"
    return "NO DATA" 
  }
  set avg_half_hour [avg_last_n $tm 30 cnt]
  if {$cnt > 0} {
    set minstat "[format %4.2f $avg_half_hour] (last $cnt minutes), "
  } else {
    set minstat ""
  }
  if {[llength $tm]>0} {
    set lminstat "[format %4.2f [expr {[lindex $tm end]/1000.0}]] (last minute), "
  } else {
    set lminstat ""
  }
  if {[llength $hours]>0} {
    set avg_last_day [avg_last_n $hours 24 cnt]
    set hourstat "[format %4.2f [expr {[lindex $hours end]/1000.0}]] (last hour), "
    append hourstat "[format %4.2f $avg_last_day] (last $cnt hours)"
    set server_running "$cnt hours"
  } else {
    if {[llength $tm]>0} {
      set dummy [avg_last_n $tm 60 cnt]
      set server_running "$cnt minutes"
    } else {
      set server_running "1 minute"
    }
    set hourstat ""
  }
  set ::server_running $server_running
  return [list $lminstat $minstat $hourstat]
}

# collect figures for views per second (when statistics are applied
# only on views)
proc currentViews {} {
  set vm [throttle trend minutes]
  set um [throttle trend user_count_minutes]
  if { $vm eq "" || $um eq ""} { return "NO DATA" }
  set views_per_sec [expr {[lindex $vm end]/60.0}]
  #ns_log notice "um='$um' vm='$vm' expr {60.0*$views_per_sec/[lindex $um end]}"
  set views_per_min_per_user [expr {60.0*$views_per_sec/[lindex $um end]}]
  set view_time [expr {$views_per_min_per_user>0 ? 
	" avg. view time: [format %4.1f [expr {60.0/$views_per_min_per_user}]]" : ""}]
  return "[format %4.1f $views_per_sec] views/sec, [format %4.2f $views_per_min_per_user] views/min/user,  $view_time"
}


if {$jsGraph} {
  # use javascript graphics

  # draw a graph in form of an html table of with 500 pixels
  proc graph {values label type} {

    switch $type {
      "Second" { set delta "D.XGridDelta=10000;\n"  }
      "Minute" { set delta "D.XGridDelta=600000;\n" }
      default  { set delta ""}
    }

    set max 1
    foreach v $values {if {$v>$max} {set max $v}}

    set size  [llength $values]
    if {$size<12} {
      set values [concat [split [string repeat 0 [expr {12-$size}]] ""] $values]
      set size [llength $values]
    }

    set end   [clock format [clock seconds] -format "%Y,%m,%d,%H,%M,%S"]
    set begin [clock format [clock scan "-$size $type"] -format "%Y,%m,%d,%H,%M,%S"]
    regsub -all {,0} $begin , begin
    regsub -all {,0} $end , end
    #ns_log Notice "begin: $begin, end: $end, $size $type"

    set diagram [subst {<SCRIPT Language='JavaScript'>
      document.open();
      var D=new Diagram();
      D.SetFrame(40, 20, 460, 120);
      D.SetBorder(Date.UTC($begin),Date.UTC($end), -$max*0.03, $max*1.03);
      D.SetText("$type","", "$label");
      D.XScale=4;
      D.YScale=1;
      $delta
      D.Font="color:#000000;font-family:Verdana;font-weight:normal;font-size:7pt;line-height:7pt;";
      D.Draw("", "#004080", false);
      var i, j, x, y, y0=D.ScreenY(0);
    }]

    #ns_log notice "--- $label $begin ... $end"

    set index 0
    set x "Date.UTC($begin)" 
    set y [lindex $values 0]
    foreach v $values {
      incr index
      set val [clock format [clock scan "[expr {$index-$size}] $type"] -format "%Y,%m,%d,%H,%M,%S"]
      #ns_log notice "--- $label $index $val // [expr {$index-$size}] $type = $v"
      regsub -all {,0} $val , val
      set x1 "Date.UTC($val)"
      #ns_log notice "--- X1 = $x1"
      set y1 $v
      append diagram [subst {
	i=D.ScreenX(Date.UTC($val));
	j=D.ScreenY($v);
	new Dot(i, j, 2, 2, "#000000", "$v");
	new Line(D.ScreenX($x),D.ScreenY($y),D.ScreenX($x1),D.ScreenY($y1),"#c0c0c0",1,"");
      }]
      set x $x1; set y $y1
    }
    append diagram "\ndocument.close();\n</SCRIPT>\n"
    return "<div style='position:relative;top:0px;height:150px;width:480px'>\n$diagram\n</div>"
  }
  


  proc counterTable {label objlist} {
    foreach {t l} $objlist {
      set trend [throttle trend $t]
       append text [subst {
	<tr><td valign='top'>[graph $trend "$label per $l" $l]</td>
	<td valign='top'>
	<table><tr><td>Max</td></tr>
      }]
      set c 1
      foreach v [throttle max_values $t] {
	incr c
	switch $t {
	  minutes {set rps "([format %5.2f [expr {[lindex $v 1]/60.0}]] rps)"}
	  hours   {set rps "([format %5.2f [expr {[lindex $v 1]/(60*60.0)}]] rps)"}
	  default {set rps ""}
	}
	set cl [expr {$c%2==0?"list-even":"list-odd"}]
	append text [subst {
	  <tr class='$cl'><td><font size='-2'>[lindex $v 0]</font></td>
	  <td align='right'><font size='-2'>[lindex $v 1] $rps</font></td></tr>
	}]
      }
      append text "</table>\n</td></tr>\n"
    }
    return $text
  }

} else {
  # no javascript graphics, use poor men's approach...

  # draw a graph in form of an html table of with 500 pixels
  proc graph values {
    set max 1
    foreach v $values {if {$v>$max} {set max $v}}
    set graph "<table cellpadding=0 cellspacing=1 style='background: #EAF2FF;'>\n"
    foreach v $values {
      set bar "<div style='height: 2px; background-color: #859db8; width: [expr {340*$v/$max}]px;'>"
      append graph "<tr><td width='350'>$bar</td></tr>\n"
    }
    append graph "</table>\n"
    return $graph
  }

  # build an HTML table from statistics of monitor thread
  proc counterTable {label objlist} {
    append text "<table>" \
	"<tr><td width=100></td><td>Trend</td><td width=300>Max</td></tr>"
    foreach {t l} $objlist {
      set trend [throttle trend $t]
      append text [subst {
	<tr><td style='text-align: center; border: 1px solid blue;'>$label per <br>$l</td>
	<td style='padding: 5px; border: 1px solid blue;'>[graph $trend]<font size=-2>$trend</font></td>
	<td style='padding: 5px; border: 1px solid blue;' valign='top'>
	<table width='100%'>
      }]
      set c 1
      foreach v [throttle max_values $t] {
	incr c
	switch $t {
	  minutes {set rps "([format %5.2f [expr {[lindex $v 1]/60.0}]] rps)"}
	  hours   {set rps "([format %5.2f [expr {[lindex $v 1]/(60*60.0)}]] rps)"}
	  default {set rps ""}
	}
	set bg [expr {$c%2==0?"white":"#EAF2FF"}]
	append text "<tr style='background: $bg'><td><font size=-2>[lindex $v 0]</font></td>
                     <td align='right'><font size=-2>[lindex $v 1] $rps</font></td></tr>"
      }
      append text "</td></td></table></tr>"
    }
    append text "</table><p>"
  }
}

# set variables for template
set views_trend [counterTable Views [list seconds Second minutes Minute hours Hour]]
set users_trend [counterTable Users [list user_count_minutes Minute user_count_hours Hour]]
set response_trend [counterTable "Avg. Response <br>Time" \
			[list response_time_minutes Minute response_time_hours Hour]]

set current_response [join [currentResponseTime] " "]
set current_load [currentSystemLoad]
array set current_threads [throttle server_threads]

set running_requests [throttle running]
set running [expr {[llength $running_requests]/2}]
if {![catch {ns_conn contentsentlength}]} {
  set background_requests [bgdelivery running]
  set background  [expr {[llength $background_requests]/2}]
  append running /$background
}
array set thread_avgs [throttle thread_avgs]

if {[info command ::tlf::system_activity] ne ""} {
  array set server_stats [::tlf::system_activity]
  set current_exercise_activity $server_stats(activity)
  set current_system_activity "$server_stats(activity) exercises last 15 mins, "
} else {
  set current_system_activity ""
}
append current_system_activity \n[currentViews]

set throttle_stats  [throttle statistics]
set active10        [throttle users nr_users_time_window]
set authUsers10     [lindex $active10 1]
set activeIP10      [lindex $active10 0]
set activeTotal10   [expr {$authUsers10 + $activeIP10}]
set active24        [throttle users nr_users_per_day]
set authUsers24     [lindex $active24 1]
set activeIP24      [lindex $active24 0]
set activeTotal24   [expr {$authUsers24 + $activeIP24}]

if {[info command ::dotlrn_community::get_community_id] ne ""} {
  set nr [throttle users nr_active_communities]
  set active_community_string "in <a href='./active-communities'>$nr communities</a> "
} else {
  set active_community_string ""
}

set active_user_string "<a href='./whos-online'>$activeTotal10 users ($authUsers10 authenticated)</a> $active_community_string active in last 10 minutes, <a href='./whos-online-today'>$activeTotal24 ($authUsers24 authenticated)</a> in last $::server_running"
set jsGraph [expr {!$jsGraph}]
set toggle_graphics_url [export_vars -base [ad_conn url] {jsGraph}]
set jsGraph [expr {!$jsGraph}]

# Parameters URL
if {[acs_user::site_wide_admin_p]} {
    set return_url [ad_return_url]
    set package_id [ad_conn package_id]
    set param_url [export_vars -base "/shared/parameters" -url {package_id return_url}]
} else {
    set param_url ""
}
