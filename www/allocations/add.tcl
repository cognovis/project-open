# File: /www/intranet/allocations/add.tcl

ad_page_contract {
    allows someone to enter in an employees allocations
    
    @param allocation_id
    @param allocated_user_id
    @param start_block
    @param return_url

    @author Mike Bryzek (mbryzek@arsdigita.com) 
    @creation-date Jan 2000
    @cvs-id add.tcl,v 3.11.2.6 2000/09/22 01:38:25 kevin Exp
} {
    allocation_id:integer,optional
    allocated_user_id:integer,optional
    start_block:optional
    return_url:optional        
}
    

ad_maybe_redirect_for_registration

set percentages [list 100 95 90 85 80 75 70 65 60 55 50 45 40 35 30 25 20 15 10 5 0]

if ![exists_and_not_null allocation_id] {
    set allocation_id [db_string next_allocation_id "select im_allocations_id_seq.nextval from dual"]

    set project_opt_list "
      <select name=group_id>
      [db_html_select_value_options project_select_options "select 
        p.group_id, ug.group_name 
        from im_projects p, user_groups ug, im_project_status ps
        where ps.project_status <> 'deleted'
        and ps.project_status_id = p.project_status_id
        and ug.group_id = p.group_id
        order by lower(group_name)"]
      </select>
    "

    set employee_opt_list "
    <select name=allocated_user_id>
    <option value=\"\">Not decided</option>
    [im_employee_select_optionlist [value_if_exists allocated_user_id]]
    </select>
    "

    set start_block_option_list "
    <select name=start_block>
    [im_allocation_date_optionlist [value_if_exists start_block]]
    </select>
    "
} else {
    db_1row select_user_id "select 
    group_id,
    user_id as allocated_user_id,
    start_block,
    to_char(start_block,'Month YYYY') as pretty_start_block,
    percentage_time,
    note
    from im_allocations
    where allocation_id = :allocation_id"

    set project_opt_list "
    [db_string project_name "select group_name from user_groups where group_id = :group_id"]\n
    [export_form_vars group_id]
    "

    set employee_opt_list "
    [db_string user_name "select last_name || ', ' || first_names from users where user_id = :allocated_user_id"]\n
    [export_form_vars allocated_user_id]
    "

    set start_block_option_list "
    $pretty_start_block\n
    [export_form_vars start_block]
    "
}

db_release_unused_handles


set page_title "Enter an allocation"
set context_bar "[ad_context_bar [list "index" "Allocations"] "Enter allocation"]"

set page_content "
<form method=post action=add-2> 
[export_form_vars allocation_id return_url]
<table>

<tr><th valign=top align=right>Project:</th>
 <td>
 $project_opt_list
 </td>
</tr>

<tr><th valign=top align=right>Employee:</th>
 <td>
 $employee_opt_list
 </td>
</tr>

<tr><th valign=top align=right>Month start:</th>
 <td>
 $start_block_option_list
 </td>
</tr>

<tr><th valign=top align=right>Percentage time:</th>
 <td>
 <select name=percentage_time>
 [html_select_options $percentages [value_if_exists percentage_time]]
 </select>
 </td>
</tr>

<tr><th valign=top align=right>Note</th>
 <td>
 <textarea name=note cols=40 rows=8 wrap=soft>[value_if_exists note]</textarea>
 </td>
</tr>

</table>

<p>
<center>
<input type=submit value=\"Submit\">
</center>
</form>
<p>
"

doc_return  200 text/html [im_return_template]

