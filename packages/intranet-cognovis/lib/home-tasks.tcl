if ![info exists page_size] {
    set page_size 25
} 

template::list::create \
    -name tasks \
    -multirow tasks \
    -key task_id \
    -elements {
	project_name {
	    label "Project Name"
	    display_template {<a href='@tasks.project_url;noquote@'>@tasks.project_name;noquote@}
	}
	task_name {
	    label "Task Name"
	    display_template {<a href='@tasks.task_url;noquote@'>@tasks.task_name;noquote@}
	}
	priority {
	    label "Prio"
	} 
	percent_completed {
	    label "%"
	}
	planned_units {
	    label "Plan"
	}
	logged_hours {
	    label "Log"
	    display_template {<a href='@tasks.timesheet_report_url;noquote@'>@tasks.logged_hours;noquote@</a>}
	}
    } \
    -orderby {
	default_value priority,desc
	priority {
	    orderby priority
	    default_direction desc
	}
	project_name {
	    orderby project_name
	    default_direction asc
	}
	percent_completed {
	    orderby percent_completed
	    default_direction desc
	}
    } \
    -page_size $page_size \
    -page_flush_p 0 \
    -page_query_name tasks_pagination


db_multirow -extend {project_url task_url timesheet_report_url} tasks select_tasks {} {
   
    set timesheet_report_url [export_vars -base "/intranet-reporting/timesheet-customer-project" {return_url {level_of_detail 99} task_id project_id }]
    set project_url [export_vars -base "/intranet-timesheet2-tasks/index" {{project_id $project_id} {view_name "im_timehseet_task_list"} {task_status_id $restrict_to_status_id}}]
    set task_url [export_vars -base "/intranet-cognovis/tasks/view" {task_id}]

    if {[string equal t $parent_red_p]} { 
	set project_name "<font color=red>$project_name</font>" 
    }

    if {[string equal t $red_p]} { 
	set task_name "<font color=red>$task_name</font>" 
    }
}





