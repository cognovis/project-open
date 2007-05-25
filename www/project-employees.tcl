ad_page_contract {
    
} {
}

array set users {}
array set projects {}

db_foreach hours "
    SELECT 
        tmp.*,
        im_projects.parent_id
    FROM
       (SELECT 
        im_hours.project_id,
        im_hours.user_id,
        SUM(hours) AS hours,
        im_name_from_user_id(im_hours.user_id) AS name
       FROM 
          im_hours,
          im_projects
       GROUP BY 
           im_hours.project_id,im_hours.user_id
       HAVING SUM(hours)>0
       ) AS tmp
    WHERE 
       tmp.project_id=im_projects.project_id
" {
    set users($user_id) $name
    
    if { ![info exists projects($project_id,$user_id)] } {
	set projects($project_id,$user_id) 0
    }
    
    set projects($project_id,$user_id) [expr $projects($project_id,$user_id)+$hours]
}

set elements {
    tree_level {
    }
    project_name {
	label "Project Name"
	link_url_eval { 
	    [return "/intranet/projects/view?[export_vars -url { project_id } ]" ]
	}
	html "nowrap"
	
    }
    cost_invoices_cache {
    }
    cost_purchase_orders_cache {
    }
    cost_bills_cache {
    }
    cost_timesheet_logged_cache {
	label cost_timesheet_logged_cache
    }
}

foreach user_id [array names users] {
    multirow extend project_list "user_$user_id"
    lappend elements "user_$user_id"
    lappend elements [list label $users($user_id) ]
}

db_multirow project_list project_list "
      select 
        project_id,
        project_name,
        parent_id,
        cost_invoices_cache,
        cost_purchase_orders_cache,
        cost_bills_cache,
        cost_timesheet_logged_cache
      from 
        im_projects
"

multirow_sort_tree project_list project_id parent_id project_name

set i 1
set last_parent_id 0
array set parent_row {}

template::multirow foreach project_list {
    if {$parent_id!=$last_parent_id} {
	set last_parent_id $parent_id
	set parent_row($tree_level) $i
    }

#    ns_write "$i $tree_level $parent_row($tree_level)\n"

    foreach user_id [array names users] {
	if { [info exists projects($project_id,$user_id)] } {
	    set hours $projects($project_id,$user_id)
	} else {
	    set hours ""
	}
	
	template::multirow set project_list $i "user_$user_id" $hours

	set j [expr $tree_level-1]
	while {$j >= 0} {
	    set row $parent_row($j)

	    set row_hours [template::multirow get project_list $row "user_$user_id"]
	    if {$row_hours==""} {
		set row_hours 0
	    }

	    template::multirow set project_list $row "user_$user_id" [expr $hours + $row_hours]
	    
	    set j [expr $j-1]
	}
    }
    incr i
}


template::list::create \
    -name project_list \
    -elements $elements




