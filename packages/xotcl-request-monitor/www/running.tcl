ad_page_contract {
    Displays last requests of a user

    @author Gustaf Neumann (adapted for interaction with controlling thread)
    @cvs-id $Id$
} -query {
  orderby:optional
} -properties {
    title:onevalue
    context:onevalue
    user_string:onevalue
}

set admin_p [acs_user::site_wide_admin_p]
if {!$admin_p} {
  ad_return_warning "Insufficient Permissions" \
      "Only side wide admins are allowed to view this page!"
  ad_script_abort
}

set running_requests [throttle running]
if {[info command bgdelivery] ne ""} {
   set background_requests [bgdelivery running]
} else {
   set background_requests [list]
}
set nr_bg  [expr {[llength $background_requests]/2}]
set nr_req [expr {[llength $running_requests]/2}]
set title "Currently Running Requests ($nr_req/$nr_bg)"
set context [list "Running Requests"]

TableWidget create t1 -volatile \
    -actions [subst {
      Action new -label Refresh -url [ad_conn url] -tooltip "Reload current page"
    }] \
    -columns {
      AnchorField user -label "User"
      Field url        -label "Url"
      Field elapsed    -label "Elapsed Time" -html { align right }
      Field background -label "Background"
    } \
    -no_data "Currently no running requests" 

set sortable_requests [list]
foreach {key elapsed} $running_requests {
  foreach {requestor url} [split $key ,] break
  set ms [format %.2f [expr {[throttle ms -start_time $elapsed]/1000.0}]]
  if {[string is integer $requestor]} {
    acs_user::get -user_id $requestor -array user
    set user_string "$user(first_names) $user(last_name)"
  } else {
    set user_string $requestor
  }
  set user_url "last-requests?request_key=$requestor"
  lappend sortable_requests [list $user_string $user_url $url $ms ""]
}
foreach {index entry} $background_requests {
  foreach {key elapsed} $entry break
  foreach {requestor url} [split $key ,] break
  set ms [format %.2f [expr {[throttle ms -start_time $elapsed]/1000.0}]]
  if {[string is integer $requestor]} {
    acs_user::get -user_id $requestor -array user
    set user_string "$user(first_names) $user(last_name)"
  } else {
    set user_string $requestor
  }
  set user_url "last-requests?request_key=$requestor"
  lappend sortable_requests [list $user_string $user_url $url -$ms "background"]
}

foreach r [lsort -decreasing -real -index 3 $sortable_requests] {
  foreach {user_string user_url url ms mode} $r break
  if {$ms<0} {set ms [expr {-1*$ms}]}
  t1 add \
      -user $user_string -user.href $user_url \
      -url $url -elapsed $ms -background $mode
}

set t1 [t1 asHTML]
