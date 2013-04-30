ad_page_contract {
    save db size 
} {
}

            # ns_log notice "run ad_monitor_db"

            ad_monitor_db_pgsql
	    ad_returnredirect "index2"
            ad_script_abort

