# /www/intranet/allocations/one-group-one-month.tcl

ad_page_contract {
    Allocations for one group (office, team, project) for
    one months
  
    @param start_block
    @param order_by_var
    @param allocation_user_id
    @param group_id

    @author teadams@arsdigita.com
    @creation-date May 2000
   
    @cvs-id one-group-one-month.tcl,v 3.12.2.9 2000/09/22 01:38:26 kevin Exp
} {
    start_block:optional
    order_by_var:optional
    allocation_user_id:optional
    group_id:naturalnum,notnull
}

set report_group_id $group_id

# warning start_block can be reassigned on this page 
#  be careful to recast start_block in your queries

set report_group_name [db_string \
                       group_name_statement \
                       "select group_name 
                        from user_groups 
                        where group_id = :report_group_id" ]

# get a list of projects for select lists

set project_options [db_html_select_value_options \
                     user_groups_select_options \
                     "select p.group_id, ug.group_name 
                        from im_projects p, user_groups ug, im_project_status ps
                       where ps.project_status <> 'deleted'
                         and ps.project_status_id = p.project_status_id
                         and ug.group_id = p.group_id
                    order by lower(group_name)"]

# percentages for the select boxes
set percentage_values [list 100 95 90 85 80 75 70 65 60 55 50 45 40 35 30 25 20 15 10 5 0 "too small to track"]

set percentage_options [list 100 95 90 85 80 75 70 65 60 55 50 45 40 35 30 25 20 15 10 5 0 "too small"]

# if not other wise provided, the report will be for this month

if ![info exist start_block] {
    set start_block  [db_string max_start_block_statement \
                      "select max(start_block)
                         from im_start_blocks 
                        where start_block < sysdate 
                          and to_char(start_block,'W') = 1"]
}

set pretty_start_block [db_string pretty_start_block_statement \
                       "select 
                          to_char(to_date(:start_block,'YYYY-MM-DD'),'Month YYYY') 
                        from dual" ]
 
set end_block  [db_string min_start_block_statement \
                "select min(start_block)
                   from im_start_blocks 
                  where start_block > :start_block
                    and start_of_larger_unit_p = 't'" ]

if {![info exists order_by_var] || [empty_string_p $order_by_var]}  {
    set order_by_var "last_name"
}

set order_by_clause "order by $order_by_var"

set order_by_last ""

# who is available in this group

set sql_query "select users.user_id, first_names || ' ' || last_name as name, 
                      avg(im_employee_percentage_time.percentage_time) as available_allocation
                 from users, (select avg(im2.percentage_time) as percentage_time, 
                                     im2.user_id,min(im2.start_block) as start_block
                                from im_employee_percentage_time im2, im_start_blocks
                               where im_start_blocks.start_block = im2.start_block(+)
                                 and im_start_blocks.start_block >= '$start_block'
                                 and im_start_blocks.start_block < '$end_block'
                               group by im2.user_id) im_employee_percentage_time
                where users.user_id = im_employee_percentage_time.user_id
                  and im_employee_percentage_time.start_block >= '$start_block'
                  and im_employee_percentage_time.start_block <'$end_block'
                  and users.user_id in (select user_group_map.user_id 
                                          from user_group_map 
                                         where group_id=$report_group_id)
             group by to_char(im_employee_percentage_time.start_block,'YYYY-MM'), 
                      users.user_id, users.first_names,users.last_name"


set allocation_list ""
db_foreach who_avaible_statement $sql_query {
    append allocation_list "<b><a href=/intranet/users/view?[export_url_vars user_id]>$name</a></b>: Available allocation percentage: $available_allocation  <br>"    

    set allocation_sublist [list]
    set hours_total 0
    set counter 0
    db_foreach sub_sql_query_1 {
        select sum(hours) as hours, group_name
          from im_hours, user_groups
         where user_id=:user_id
           and im_hours.on_what_id = user_groups.group_id
           and day >= :start_block
           and day < :end_block
      group by group_name
    } {
	if {$counter == 0} {
	   append allocation_list "Self reported:<br> "
	}
	incr counter
	set hours_total [expr $hours_total + $hours]
	lappend allocation_sublist [list $group_name $hours]
    } 

    foreach allocation_sublist_element $allocation_sublist {
	set group_name [lindex $allocation_sublist_element 0]
	set hours [lindex $allocation_sublist_element 1]

	if { $hours_total == 0 } {
	    set percent_of_total_hours "N/A"
	} else {
	    set percent_of_total_hours [expr round((100*$hours)/$hours_total)]
	}
	append allocation_list "$group_name: $hours hours ($percent_of_total_hours% of total)<br>"
    }


    if {$counter > 0} {
	append allocation_list "Total: $hours_total hours 
                                <p>Reviewed summary for company reports:<br>"
    } else {
	append allocation_list "Prediction:<br>"
    }


    db_foreach sub_sql_query_2 {
        select allocation_id, percentage_time, 
               too_small_to_give_percentage_p,
               group_id as allocated_group_id, 
               (select group_name from user_groups
                 where user_groups.group_id = im_allocations.group_id) 
                as allocated_group_name,
               note 
          from im_allocations
         where user_id = :user_id
           and im_allocations.start_block = :start_block
    } {
	if {$too_small_to_give_percentage_p == "t"} {
	    set percentage_time "too small to track"
	}

	append allocation_list \
        "<select name=group_id_for_allocation.$allocation_id>
         <option value=\"no_change\">$allocated_group_name</option>$project_options</select>
         <select name=percentage_time_for_allocation.$allocation_id>
         <option value=\"no_change\">$percentage_time</option>[ad_generic_optionlist $percentage_values $percentage_options]</select> Note: <input type=text name=note_for_allocation.$allocation_id [export_form_value note]>
<input type=hidden name=hidden_note_for_allocation.$allocation_id [export_form_value note]><br>"
    }

    # allow them to add more
    
    for {set y 0} {$y < 3} {incr y} {
	incr y
	#append allocation_list "  <select name=group_id_[set y]_for_user_[set user_id]><option value=\"\">Project</option>$project_options</select>
        #<select name=percentage_[set y]_for_user_[set user_id]><option value=\"0\">Percentage</option>[ad_generic_optionlist $percentage_values $percentage_options]</select> 
        #Note: <input type=text name=note_[set y]_for_user_[set user_id] maxlength=300><br>"
	append allocation_list "  <select name=group_id_for_user.${y},${user_id}><option value=\"\">Project</option>$project_options</select>
<select name=percentage_for_user.${y},${user_id}><option value=\"0\">Percentage</option>[ad_generic_optionlist $percentage_values $percentage_options]</select> 
Note: <input type=text name=note_for_user.${y},${user_id} maxlength=300><br>"
    }

    append allocation_list "</td></td></tr>"

}
                                  
set page_title "$pretty_start_block allocations for employees in $report_group_name"
set context_bar "[ad_context_bar "Project allocations"]"
   
set page_body "
<table width=100% cellpadding=5><tr><td>
<form action=one-group-one-month method=post>
[export_form_vars group_id]
Change month:
<select name=start_block>
[im_allocation_date_optionlist $start_block "t"]
</select>
<input type=submit name=submit value=Go>
</form>
</td><td align=right valign=top><font size=-1>
<a href=../projects/index?[export_ns_set_vars]>Summary view</a> |
<a href=../projects/money?[export_ns_set_vars]>Financial view</a> 
</font></table>
<form action=one-group-one-month-add-2 method=post>
[export_form_vars start_block]
<input type=hidden name=page_group_id value=\"$group_id\">
"

if { [empty_string_p $allocation_list] } {
    append page_body "<b>There are no allocations in the database right now.</b><p>\n"
} else {
    append page_body "

$allocation_list
<p>
<center>
<input type=submit name=submit value=Submit>
</center>
</form>
"
}


doc_return  200 text/html [im_return_template]

