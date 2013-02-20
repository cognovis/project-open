# /www/admin/monitoring/top/index.tcl

ad_page_contract {
    Displays reports from saved top statistics.

    @author alessandro.landim@teknedigital.com.br
    @creation-date Ago 2006
    @cvs-id        $Id: index.tcl,v 1.3 2006/09/12 18:47:03 alessandrol Exp $
} {
    
}

set title "TOP"
set context [list "TOP"]

set top_id [db_string newest_top_id {}] 
set max_cpu_pct [db_string max_cpu_pct {}]

with_catch error {
    db_1row  monitoring_top {}
} {
    ad_returnredirect "index2"
    ad_script_abort
}

set memory_in_use [expr ($memory_real - $memory_free) / 1024]
set memory_real_MB [expr $memory_real / 1024] 
set pct_memory_in_use [expr ($memory_in_use * 100) / $memory_real_MB] 
set cpu_total [expr 100 - $cpu_idle]


set swap_real [expr ($memory_swap_free + $memory_swap_in_use) / 1024]
set memory_swap_in_use [expr $memory_swap_in_use / 1024]
set pct_swap_in_use [expr ($memory_swap_in_use * 100) / $swap_real]


set memory_color [img_color -value $pct_memory_in_use]
set cpu_color [img_color -value $cpu_total]
set swap_color [img_color -value $pct_swap_in_use]



template::list::create -name procs \
                       -multirow procs \
		       -no_data "Sem dados no momento" \
		       -page_flush_p 1 \
		       -elements {
	 		   command        { label "[_ monitoring.command]" }
                           cpu_pct        { label "[_ monitoring.cpu_pct]" }
		           username       { label "[_ monitoring.username]" }
                           pid            { label "[_ monitoring.pid]" }
 			   timestamp      { label "[_ monitoring.timestamp]" }
 			   action         { label "[_ monitoring.action]" 
						display_template { <a href="one-pid?pid=@procs.pid@&command=@procs.command@"> histórico</a> } 
					  }
			}
			





db_multirow procs monitoring_top_proc_cpu {} {
}
