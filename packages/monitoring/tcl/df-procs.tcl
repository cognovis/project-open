# /packages/monitoring/tcl/df-procs.tcl
ad_library {
   @author roop@teknedigital.com.br [roop@teknedigital.com.br]
}


ad_proc ad_monitor_df {} { 
    ad_monitor_df grava o resultado do comando df -h com estatisticas de disco

} {
    ns_log notice "rum df monitoring"
    # lista dados da saida
    set proc_var_list [list filesystem size used avail used_percent mounted]

    if [catch { set df_output [eval "exec df -h"] } errmsg] {
        ns_log Error "ad_monitor_top_df: top could not be df - $errmsg"
        return
    }
    
    set df_list [split $df_output "\n"]
     
    # id for this iteration of df
    set df_id [db_nextval ad_monitoring_top_df_id]
    
    db_dml df_id_insert "insert into ad_monitoring_df (df_id,timestamp) values ($df_id,now())"

    # get rows  
    set line_num 0  
    foreach line $df_list {
        
            #compress multiple spaces
            regsub -all {[ ]+} [string trim $line] " " line    
            set dev_list [split $line]

	    
            #skip blank lines
            if { [llength $dev_list] < 2 } { continue } 
            #skip teh header
	    if {$line_num == 0} {
	       incr line_num
	       continue  
	    }
	    
            set filesystem   [lindex $dev_list 0]
            set size         [lindex $dev_list 1]
            set used         [lindex $dev_list 2]
            set avail        [lindex $dev_list 3]
            set used_percent [lindex $dev_list 4]
            set mounted      [lindex $dev_list 5]
	    
            set df_item_id [db_nextval ad_monitoring_top_df_item_id]

            db_dml df_info_insert "
            insert into ad_monitoring_top_df_item (
	       df_item_id,
	       df_id,
	       filesystem,
	       size,
	       used,
	       avail,
	       used_percent,
	       mounted
	    ) values (
	       $df_item_id,
	       $df_id,
	       '$filesystem',
	       '$size',
	       '$used',
	       '$avail',
	       '$used_percent',
	       '$mounted'
	     )
	     "
	} 

    
}

