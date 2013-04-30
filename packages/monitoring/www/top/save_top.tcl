ad_page_contract {
    save top data 
} {
}

            # ns_log notice "run ad_monitor_top"
         
            #for { set i 0 } { $i < 100 } { incr i} {   
            ad_monitor_top
            #ns_log Notice "GRAVANDO NO BD: POSIÇÃO: $i"
            #}
	    ad_returnredirect "index2"
            ad_script_abort

