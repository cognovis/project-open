# /www/intranet/allocations/index.tcl

ad_page_contract {
 
    Top level view of all allocations
    
    @param start_block
    @param end_block
    @param order_by_var
    @param allocation_user_id
    
    @author mbryzek@arsdigita.com
    @creation-date January 2000
    @cvs-id index.tcl,v 3.23.2.10 2000/09/22 01:38:26 kevin Exp
} {
    start_block:optional
    end_block:optional
    order_by_var:optional
    allocation_user_id:integer,optional  
}

set user_id [ad_maybe_redirect_for_registration] 
# warning
# start_block can be reassigned on this page 
#  be careful to recast start_block in your queries

if { [exists_and_not_null start_block] && [exists_and_not_null end_block] } {
    if { ![db_string start_before_end_test "select count(*) from dual where :start_block < :end_block"] } {
	ad_return_complaint "Invalid Date Range" "<li> Please make sure the start date is before the end date"
	return
    }
}

# if not other wise provided, the report will be for one month

if { ![info exist end_block] || [empty_string_p $end_block] } {
    set end_block [db_string end_block_statement "select max(start_block)
                                     from im_start_blocks 
                                     where start_block < add_months(sysdate,1)
                                     and to_char(start_block,'W') = 1"]
}

if { ![info exist start_block] || [empty_string_p $start_block] } {
    set start_block  [db_string start_block_statement "select max(start_block)
                                        from im_start_blocks 
                                        where start_block < :end_block
                                              and to_char(start_block,'W') = 1"]
}

lappend where_clauses "users.user_id(+) = im_allocations.user_id"
lappend where_clauses "im_projects.group_id = im_allocations.group_id"
lappend where_clauses "im_allocations.start_block >= :start_block"
lappend where_clauses "im_allocations.start_block < :end_block"
lappend where_clauses "im_allocations.percentage_time > 0"

set where_clauses [join $where_clauses " and "]

if {![info exists order_by_var] || [empty_string_p $order_by_var]}  {
    set order_by_var "last_name"
}

set order_by_clause "order by $order_by_var"

set order_by_last ""

if {$order_by_var == "last_name"} {
    set interface_separation "allocated_name"    
} elseif {$order_by_var == "group_id"} { 
   set interface_separation "project_name"
} else {
   set interface_separation "percentage_time"
}



set num_reporting_time_blocks 0
db_foreach note_start_block  {
    select note, start_block as allocation_note_start_block 
    from im_start_blocks
    where start_block >= :start_block
        and  start_of_larger_unit_p = 't'
        and start_block < :end_block
} {
    set allocation_note($allocation_note_start_block) "$note <a href=note-edit?[export_url_vars allocation_note_start_block start_block end_block]>edit</a>"
    incr num_reporting_time_blocks

}

## employee starting dates are recorded weekly
## allocation are recorded monthly
## so we do not limit this query to 
## start_of_larger_unit_p = t
set count 0

db_foreach employee_percentage_time_min_start_block {
    select 
    min(valid_start_blocks.start_block) as temp_start_block,  
    sum(im_employee_percentage_time.percentage_time)/100 as percentage_time
    from im_employee_percentage_time, 
         (select start_block
          from im_start_blocks 
          where start_block >= :start_block
                and start_block < :end_block) valid_start_blocks 
    where valid_start_blocks.start_block = im_employee_percentage_time.start_block
    group by im_employee_percentage_time.start_block
    order by temp_start_block
} {
    # we need to add all the units available for the range (from the first
    # Sunday of the month to the next
    if {[info exists  allocation_note($temp_start_block)]} {
	# this is the first Sunday of the month
	set number_developer_units_available($temp_start_block) $percentage_time
	set first_week_start_block $temp_start_block
	set count 1
	
    } else {
	if { ![info exists number_developer_units_available($temp_start_block)] } {
	    set number_developer_units_available($temp_start_block) 0
	}
	set number_developer_units_available($temp_start_block) [expr  ($number_developer_units_available($temp_start_block)*$count + $percentage_time)/($count + 1)]
	incr count
    }

}

db_foreach percentage_time_start_block "select 
    sum(percentage_time)/100 as percentage_time, im_allocations.start_block as temp_start_block
    from im_allocations, im_projects, im_start_blocks, users
    where $where_clauses
    and im_allocations.start_block = im_start_blocks.start_block
    and im_start_blocks.start_of_larger_unit_p = 't'
    group by im_allocations.start_block
    order by temp_start_block
" {
    set number_developer_units_scheduled($temp_start_block)  "$percentage_time"
} 

set ctr 0
set summary_text ""

db_foreach start_block_date {
    select start_block as temp_start_block, 
           to_char(start_block, 'Month  YYYY') as temp_pretty_start_block
    from im_start_blocks 
    where start_block >= :start_block
    and start_block < :end_block
    and  start_of_larger_unit_p = 't'
    order by temp_start_block
} {
    if { $ctr % 2 == 0 } {
	set background_tag " bgcolor=\"[ad_parameter TableColorOdd intranet white]\""
    } else {
	set background_tag " bgcolor=\"[ad_parameter TableColorEven intranet white]\""
    }
    incr ctr
    if { ![info exists number_developer_units_available($temp_start_block)] } {
	set number_developer_units_available($temp_start_block) 0
    }
    append summary_text "
<tr$background_tag>
  <td>$temp_pretty_start_block</td>
  <td>$allocation_note($temp_start_block)</td>
  <td>$number_developer_units_available($temp_start_block)</td>
"
    if { [info exists number_developer_units_scheduled($temp_start_block)] } {
	append summary_text "  <td>$number_developer_units_scheduled($temp_start_block)</td>"
    } else {
	append summary_text "  <td>&nbsp;</td>"
    }
    append summary_text "\n</tr>\n"
} 





set counter 0
set allocation_list ""
db_foreach im_projects_group_id_user_id_allocation_id " select im_projects.group_id, users.user_id, allocation_id, 
    group_name as project_name, percentage_time, im_allocations.start_block as temp_start_block,
    to_char(im_allocations.start_block, 'Month YYYY') as month_start, 
    im_allocations.note,
    first_names || ' ' || last_name as allocated_name
    from im_allocations, im_projects, users, user_groups, im_start_blocks
    where $where_clauses
    and user_groups.group_id = im_projects.group_id
    and im_allocations.start_block = im_start_blocks.start_block
    and im_start_blocks.start_of_larger_unit_p = 't'
    $order_by_clause
" {
    incr counter
   
    if { $order_by_last != [set $interface_separation] } {
	append allocation_list "<tr><td>&nbsp;</td></tr>"
    }

    set allocated_user_id $user_id
    append allocation_list "<tr>
    <td>$month_start</td>
    <td><a href=\"project?[export_url_vars group_id]\">$project_name</a></td>
    <td><a href=user?allocation_user_id=$user_id&[export_url_vars temp_start_block]>$allocated_name</a></td>
    <td>$percentage_time % </td>
    <td><font size=-1>$note</font></td>
    <td><a href=add?[export_url_vars allocation_id allocated_user_id]&return_url=[ns_urlencode [ns_conn url]]>edit</a></td>
    </tr>"

    set order_by_last [set $interface_separation]

}

## employee starting dates are recorded weekly
## allocation are recorded monthly
## so we do not limit the available part of this query to 
## start_of_larger_unit_p = t

set num_weeks [db_string num_weeks_statement "select count(start_block) 
                                 from im_start_blocks where start_block >= :start_block
                                 and start_block < :end_block" ]

set over_allocated ""
set under_allocated ""
db_foreach employee_starting_dates {
    select 
    first_names || ' ' || last_name as name, 
    users.user_id,
    round(nvl(available_view.percentage_time,0), 2) as percentage,
    round(nvl(scheduled_view.percentage_time,0), 2) as scheduled_percentage
    from im_employees, users,
    (select sum(percentage_time)/:num_weeks as percentage_time, user_id 
    from im_employee_percentage_time
    where start_block >= :start_block
    and start_block < :end_block
    group by user_id) available_view,
    (select sum(percentage_time)/:num_reporting_time_blocks as percentage_time, user_id from im_allocations, im_start_blocks
    where im_allocations.start_block >= :start_block
    and im_allocations.start_block < :end_block
    and im_allocations.start_block = im_start_blocks.start_block
    and im_start_blocks.start_of_larger_unit_p = 't'
    group by user_id) scheduled_view
    where im_employees.user_id = users.user_id
    and im_employees.user_id = available_view.user_id (+)
    and im_employees.user_id = scheduled_view.user_id (+)
    order by last_name
} {
    if {$scheduled_percentage <= [expr $percentage - 5]} {
	append under_allocated "<li><a href=user?allocation_user_id=$user_id&[export_url_vars temp_start_block]>$name</a> (Scheduled $scheduled_percentage% of $percentage%  available)<br>"
    }
    if {$scheduled_percentage >= [expr $percentage + 5]} {
	append over_allocated "<li><a href=user?allocation_user_id=$user_id&[export_url_vars temp_start_block]>$name</a> (Scheduled $scheduled_percentage% of $percentage%  available)<br>"
    }
}

if { [empty_string_p $over_allocated] } {
    set over_allocated "  <li><i>none</i>"
} 
if { [empty_string_p $under_allocated] } {
    set under_allocated "  <li><i>none</i>"
} 

db_release_unused_handles


set page_title "Allocations for [util_IllustraDatetoPrettyDate $start_block] to [util_IllustraDatetoPrettyDate  $end_block]"
set context_bar "[im_context_bar "Project allocations"]"


set page_body "
<table width=100% cellpadding=0 cellspacing=0><tr><td>
<form action=index method=post>
From:
<select name=start_block>
[im_allocation_date_optionlist $start_block "t"]
</select>
to:
<select name=end_block>
[im_allocation_date_optionlist $end_block "t"]
</select>

<input type=submit name=submit value=Go>
</form>
</td><td align=right valign=top><font size=-1>
<a href=../projects/index?[export_ns_set_vars]>Summary view</a> |
<a href=../projects/money?[export_ns_set_vars]>Financial view</a> 
</font></table>
<p>

<h3>Summary</h3>
<table cellpadding=2 cellspacing=2 border=1>
<tr bgcolor=\"[ad_parameter TableColorHeader intranet white]\">
  <th>Month</th>
  <th>Note</th>
  <th>Available staff</th>
  <th>Scheduled staff</th>
</tr>
$summary_text
</table>

<p>

<h3>Allocation Details</h3>
"

if { [empty_string_p $allocation_list] } {
    append page_body "<b>There are no allocations in the database right now.</b><p>\n"
} else {
    append page_body "

<table cellpadding=0 cellspacing=2>
<tr><th>Month</th>
<th><a href=index?[export_ns_set_vars url order_by_var]&order_by_var=group_id>Project</a></th>
<th><a href=index?[export_ns_set_vars url order_by_var]&order_by_var=last_name>Employee</a></th>
<th><a href=index?[export_ns_set_vars url order_by_var]&order_by_var=percentage_time>% of full</a></th><th>Note</td><th>Edit</td></tr>
$allocation_list
</table>
"
}

append page_body "
<h3>Allocation problems</h3>
<b>Under allocated</b><br>
<ul>
$under_allocated
</ul>
<b>Over allocated</b><br>
<ul>
$over_allocated
</ul>

<p>
<a href=\"add?[export_url_vars start_block]\">Add an allocation</a></ul><p>
"

doc_return  200 text/html [im_return_template]

