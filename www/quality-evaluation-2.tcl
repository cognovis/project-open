# /www/intranet/quality/quality-evaluation-2

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    @author Guillermo Belcic Bardaji
    @cvs-id 
} {
    task_id:integer,notnull

    { evaluation 0 }
    { sample_size 0 }
    

    mistranslation:array,optional
    accuracy:array,optional
    terminology:array,optional
    language:array,optional
    style:array,optional
    country:array,optional
    consistency:array,optional
    
    { comments "" }
}

# ---------------------------------------------------------------
# 2. Defaults & Security
# ---------------------------------------------------------------

# User id already verified by filters
set user_id [ad_get_user_id]
set today [lindex [split [ns_localsqltimestamp] " "] 0]
set current_user_id [ad_maybe_redirect_for_registration]

set page_title "Quality"
set context_bar [ad_context_bar_ws $page_title]


if { $evaluation != "0" } {
    db_1row task_evaluation {
	select 
		p.expected_quality_id
	from 
		im_projects p,
		im_tasks t
	where 
		p.group_id = t.project_id 
		and t.task_id = :task_id
    }
    set allowed_error_percentage 0
    switch $expected_quality_id {
	110 { # Premium Quality
	    set allowed_error_percentage 1
	}
	111 { # High Quality
	    set allowed_error_percentage 2
	}
	112 { # Average Quality
	    set allowed_error_percentage 5
	}
	113 { # Draft Qaulity
	    set allowed_error_percentage 10
	}
    }
    
    set report_id [db_nextval "quality_report_id"]
    
    set insert_report "
    insert into im_trans_quality_reports 
    values ($report_id,$task_id,'$today',$current_user_id,$sample_size,$allowed_error_percentage,'$comments')"
    db_transaction {
	db_dml insertion_quality_report $insert_report
    }
    
    set sql_list [list]
    
    db_foreach qualities_type "
	select
		category_id,
		category
	from
		categories
	where
		category_type like 'Intranet Quality Type'
	order by
		category_id" {
		    set errors_list [array get [string tolower $category]] 
		    
		    set type 1
		    set evalua 0
		    foreach errors $errors_list {
			if { $type } {
			    set error_type $errors
			    set type 0
			    set value 1
			} else {
			    if { "" == $errors } {
				set error_value 0
			    } else {
				set error_value $errors
			    }
			    set evalua 1 
			}
			if { $evalua } {
			    set cmd "set $error_type $error_value"
			    eval $cmd
			    set evalua 0
			    set type 1
			}
		    }
		    lappend sql_list "insert into im_trans_quality_entries
			values ($report_id,$category_id,[expr $minor * 1],[expr $major * 5],[expr $critical* 10])"
		}
    db_transaction {
	for {set i 0} {$i < [llength $sql_list]} {incr i} {
	    db_dml query_$i [lindex $sql_list $i]
	}
    }
	
}

ad_returnredirect "quality-report?[export_url_vars task_id]"

