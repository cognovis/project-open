# /www/intranet/allocations/user.tcl

ad_page_contract {
    Shows all allocations for a specified user

    @param allocation_user_id
    @param order_by_var
    @param temp_start_block 

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id user.tcl,v 3.14.2.7 2000/09/22 01:38:27 kevin Exp
} {
    allocation_user_id:integer
    { order_by_var "start_block" }
    { temp_start_block "" }
}


if { [empty_string_p $temp_start_block] } {
   set temp_start_block [db_string temp_start_block_statement \
	   "select max(start_block) from im_start_blocks 
            where start_block < sysdate and to_char(start_block,'W') = 1"]
}

set allocated_name [db_string allocated_name_statement \
                    "select first_names || ' ' || last_name as allocated_name 
                     from users where user_id = :allocation_user_id" -default ""]

# check ofr valid allocation_user_id to prevent url surgery
if ![exists_and_not_null allocated_name] {
    ad_return_error "Invalid allocation_user_id." "Maybe you did a little url surgery."
}

set order_by_clause "order by $order_by_var"
set order_by_last ""

if {$order_by_var == "group_id"} { 
   set interface_separation "project_name"
} else {
   set interface_separation "start_block"
}

# This table shows only one month but includes projects 
# with zero allocation. Sum hours spent on project and generate
# percent actual time by dividing by total hours.

set sql_query  \
"select 
   im_projects.group_id, 
   im_allocations.user_id, 
   allocation_id, 
   group_name as project_name, 
   nvl(percentage_time,0) percentage_time, 
   im_allocations.start_block,
   to_char(to_date('$temp_start_block'), 'Month YYYY') as month_start, 
   im_allocations.note, 
   sum(nvl(hours,0)) as total_hours
 from im_allocations, im_projects, user_groups, im_hours
 where 1 = 1
   and im_allocations.user_id(+) = :allocation_user_id
   and im_projects.group_id = im_allocations.group_id(+)
   and im_hours.user_id(+) = :allocation_user_id
   and im_projects.group_id = im_hours.on_what_id(+)
   and im_hours.day(+) between :temp_start_block and add_months(:temp_start_block, 1)
   and im_allocations.start_block(+) = :temp_start_block
   and user_groups.group_id = im_projects.group_id
   and (im_hours.hours > 0 or percentage_time > 0)
group by im_allocations.user_id,
   allocation_id, 
   percentage_time, 
   im_allocations.start_block, 
   im_allocations.note,
   im_projects.group_id, 
   group_name
$order_by_clause"


set counter 0

set sum_hours 0
set sum_allocation 0
set allocation_list ""

db_foreach  one_month_allocation $sql_query {
    incr counter
   
    # Need a valid start_block for edit
    if { [empty_string_p $start_block] } {set start_block $temp_start_block}

    if { $order_by_last != [set $interface_separation] } {
	append allocation_list "<tr><td>&nbsp;</td></tr>"
    }

    # Total hours logged
    set sum_hours [expr $sum_hours + $total_hours]
    # Total allocation to prorate actual hours
    set sum_allocation [expr $sum_allocation + $percentage_time]

    # Need valid user_id for edit
    if { [empty_string_p $user_id] } { set user_id $allocation_user_id }

    append allocation_list "<tr>
<td>$month_start</td>
<td><a href=\"project?[export_url_vars group_id]\">$project_name</a></td>
<td align=right>\[expr int($total_hours / \$sum_hours * \$sum_allocation)] %</td>
<td align=right>$percentage_time % </td>
<td><a href=add?[export_url_vars allocation_id]&return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]>edit</a></td>
<td><font size=-1>$note</font></td>
</tr>"

    set order_by_last [set $interface_separation]

}
if { $sum_hours == 0 } { 
    set sum_hours 1 
}

set allocation_list [subst $allocation_list]

if { $counter == 0 } {
    append allocation_list "<br>There are no allocations in the database right now.<p>"
}

db_release_unused_handles

set page_title "Allocations for $allocated_name"
set context_bar "[im_context_bar [list "index" "Project allocations"] "One employee"]"

set allocated_user_id $allocation_user_id
doc_return  200 text/html " 
[im_header]

<table>
<tr><th><a href=user?[export_ns_set_vars url order_by_var]&order_by_var=start_block>Month Year</a></th>
<th><a href=user?[export_ns_set_vars url order_by_var]&order_by_var=group_id>Project</a></th>
<th><a href=user?[export_ns_set_vars url order_by_var]&order_by_var=total_hours>Actual</a></th>
<th><a href=user?[export_ns_set_vars url order_by_var]&order_by_var=percentage_time>Allocated</a></th>
<th></th>
<th>Note</th>
</tr>
$allocation_list
</table>
<p>
<a href=\"add?[export_url_vars allocated_user_id start_block]&return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]\">Add an allocation</a></ul><p>
[im_footer]"


