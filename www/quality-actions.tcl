# /www/intranet/quality/quality-actions.tcl

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    @author Guillermo Belcic Bardaji
    @cvs-id 
} {
    task_id:optional
    group_id:optional,integer
    assign_report:array,optional
    delete_report:optional
    del:array,optional
    { evaluation 0 }
    { sample_size 0 }
    { comments "" }
}

# ---------------------------------------------------------------
# 2. Defaults & Security
# ---------------------------------------------------------------

# User id already verified by filters
set user_id [ad_get_user_id]
set today [lindex [split [ns_localsqltimestamp] " "] 0]
set current_user_id [ad_maybe_redirect_for_registration]
set page_title "Quality Control"
set context_bar [ad_context_bar_ws $page_title]


if { [info exist assign_report] } {

    set tasks [list [array names assign_report]]
    if { [llength tasks] == 1 } {
	set task_id [lindex $tasks 0]
	ad_returnredirect "quality-evaluation?[export_url_vars task_id]"
    } else {
	
    }
    
}



if { [info exist delete_report] && [string equal "Del" $delete_report] } {
    set tasks [array names del]
    set sql_for_reports_from_task_id "select report_id from im_trans_quality_reports where task_id in ("
    set first_loop 1
    set cont 1
    foreach task $tasks {
	append sql_for_reports_from_task_id "$task"
	if { $cont < [llength $tasks] } {
	    incr cont
	    append sql_for_reports_from_task_id ","
	}
    }
    append sql_for_reports_from_task_id ")"
    set del_entry [list]
    set del_report [list]
    db_foreach reports_from_task_id $sql_for_reports_from_task_id {
        lappend del_entry "delete from im_trans_quality_entries where report_id = $report_id"
        lappend del_report "delete from im_trans_quality_reports where report_id = $report_id"
    }
    db_transaction {
        for {set i 0} {$i < [llength $del_entry]} {incr i} {
            db_dml query_$i [lindex $del_entry $i]
	    db_dml query_$i [lindex $del_report $i]
        }
    }
    
    ad_returnredirect "quality-control?[export_url_vars group_id]"
}
