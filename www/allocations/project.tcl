# File: /www/intranet/allocations/project.tcl

ad_page_contract {
    
    Shows allocations for a specific project
    @param group_id
    @param order_by_var:optional
    
    @author Mike Bryzek (mbryzek@arsdigita.com)
    @creation-date Jan 2000
    @cvs-id project.tcl,v 3.9.2.9 2000/09/22 01:38:26 kevin Exp
} {
    group_id:integer,notnull
    order_by_var:optional
}



set exception_count 0
set errors ""
if { [db_0or1row select_group_id "select group_id from user_groups where group_id = :group_id" ] == 0 } {
    incr exception_count
    append errors "  <li> Trying to process an invalid group_id.\n"
}    				       
 
if { ![empty_string_p $errors] } {
    ad_return_complaint $exception_count $errors
    return
}
   
lappend where_clauses "users.user_id(+) = im_allocations.user_id"
lappend where_clauses "im_projects.group_id = im_allocations.group_id"
lappend where_clauses "im_allocations.group_id = :group_id"
lappend where_clauses "im_allocations.percentage_time > 0"

if {![info exists order_by_var] || [empty_string_p $order_by_var]}  {
    set order_by_var "im_allocations.start_block"
}


set order_by_last ""

if {$order_by_var == "group_id"} { 
    set interface_separation "project_name"
} else {
    set interface_separation "start_block"
}



# take the most recent allocation for this user for this start_block
# Note: for some reason, a bind variable in order by clause will be ignored. So we use interpolation here.

set return_url [im_url_with_query]

set sql "select 
 im_projects.group_id, 
 users.user_id, 
 allocation_id, 
 group_name as project_name, 
 percentage_time, 
 im_allocations.start_block,
 to_char(im_allocations.start_block, 'Month, YYYY') as month_start, 
 im_allocations.note,
 first_names || ' ' || last_name as allocated_name
from im_allocations, im_projects, im_start_blocks, users, user_groups
where [join $where_clauses " and "]
and im_start_blocks.start_block = im_allocations.start_block
and im_start_blocks.start_of_larger_unit_p = 't'
and user_groups.group_id = im_projects.group_id
order by $order_by_var"

db_foreach select_info $sql {
    append allocation_list "
    <tr>
    <td>$month_start</td>
    <td><a href=\"user?allocation_user_id=$user_id\">$allocated_name</a></td>
    <td>$percentage_time % <td><a href=add?[export_url_vars group_id user_id start_block percentage_time allocation_id return_url]>edit</a></td>
    <td><font size=-1>$note</font></td>
    </tr>
    "
    set order_by_last [set $interface_separation]

} if_no_rows {
    append allocation_list "<br>
    There are no allocations in the database right now.<p>"

    set project_name [db_string select_group_name "select
    group_name from user_groups where group_id = :group_id" ]
    
    #get the start block too!
    set start_block [db_string select_start_block "select 
    get_start_week(im_projects.start_date) as start_block
    from im_projects where group_id = :group_id" ]
}              


set page_title "Allocations for $project_name"
set context_bar "[im_context_bar [list "index" "Project allocations"] "One project"]"


set page_content "
[im_header]

<table cellpadding=5>
<tr><th>Month</th>
<th><a href=project?[export_ns_set_vars url order_by_var]&order_by_var=group_id>Employee</a></th>
<th><a href=project?[export_ns_set_vars url order_by_var]&order_by_var=percentage_time>% of full</a></th><th>Edit</td><th>Note</td></tr>
$allocation_list
</table>
<p>
<a href=\"add?[export_url_vars start_block group_id]\">Add an allocation</a></ul><p>
[im_footer]"



doc_return  200 text/html $page_content
