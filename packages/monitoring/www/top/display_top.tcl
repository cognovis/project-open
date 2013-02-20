# monitoring/top/display_top.tcl

ad_page_contract {
    Displays one TOP

    @author        Alessandro Landim <alessandro.landim@teknedigital.com.br>

} {
  {top_id}
}

set title "Display one TOP"
set context [list "Display one TOP"]


db_multirow top select_top {} {
}


set memory_used [expr $memory_real - $memory_free]

set memory_swap_real [expr $memory_swap_free + $memory_swap_in_use]

db_multirow top_procs select_top_proc {} {
}

