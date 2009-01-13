# /packages/intranet-trans-invoices/www/new-2.tcl
#
# Copyright (C) 2003-2004 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    Receives a list of projects and displays all Tasks of these projects,
    ordered by project, allowing the user to modify the "billable units".
    Provides a button to advance to "new-3.tcl".

    @author frank.bergmann@poject-open.com
} {
    { select_project:multiple }
    invoice_currency
    target_cost_type_id:integer
    { return_url ""}
}

# ---------------------------------------------------------------
# 2. Defaults & Security
# ---------------------------------------------------------------

# User id already verified by filters
set user_id [ad_maybe_redirect_for_registration]
set current_user_id $user_id

set page_focus "im_header_form.keywords"
set view_name "invoice_tasks"
set page_title "New Translation Invoice"
set context_bar [im_context_bar $page_title]

set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"
set required_field "<font color=red size=+1><B>*</B></font>"

if {![im_permission $user_id add_invoices]} {
    ad_return_complaint "[_ intranet-trans-invoices.lt_Insufficient_Privileg]" "
    <li>[_ intranet-trans-invoices.lt_You_dont_have_suffici]"    
}

set allowed_cost_type [im_cost_type_write_permissions $current_user_id]
if {[lsearch -exact $allowed_cost_type $target_cost_type_id] == -1} {
    ad_return_complaint "Insufficient Privileges" "
        <li>You can't create documents of type \#$target_cost_type_id."
    ad_script_abort
}

# Should the "Aggregate Tasks" checkbox be "checked" or "disabled" by default?
set aggregate_tasks_checkbox_enabled [parameter::get_from_package_key -package_key intranet-trans-invoices -parameter "AggregateTasksCheckboxEnabled" -default "checked"]


if {[info exists select_project]} {
    set project_id $select_project
    if {[llength $select_project] > 1} {
	set project_id [lindex $select_project 0]
    }
    set project_name [db_string project_name "
	select project_name 
	from im_projects 
	where 
		project_id = :project_id
     " -default ""]
    if {"" != $project_name} {
	append page_title " for Project '$project_name'"
    }
}

# ---------------------------------------------------------------
# 3. Check the consistency of the select project and get client_id
# ---------------------------------------------------------------

# select tasks only from the selected projects ...
# and form a $projects_where_clause that allows to select
# only from these projects.
set in_clause_list [list]
foreach selected_project $select_project {
        lappend in_clause_list $selected_project
}
# Simple projects_were: Select only the selected projects
# set projects_where_clause "and p.project_id in ([join $in_clause_list ","])"

# Recursive projects_where: Select both parent and subprojects
set projects_where_clause "and p.project_id in (
      select
        children.project_id
      from
        im_projects parent,
        im_projects children
      where
        children.project_status_id not in ([im_project_status_deleted],[im_project_status_canceled])
        and children.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey)
        and parent.project_id in ([join $in_clause_list ","])
)"


# check that all projects are from the same client
set num_clients [db_string select_num_clients "
select
        count(*)
from
        (select distinct company_id
        from im_projects
        where project_id in ([join $in_clause_list ","])
        ) s
"]

if {$num_clients > 1} {
        ad_return_complaint "[_ intranet-trans-invoices.lt_You_have_selected_mul]" "
        <li>[_ intranet-trans-invoices.lt_You_have_selected_mul_1]<BR>
            [_ intranet-trans-invoices.lt_Please_backup_and_res]"
}


# now we know that all projects are from a single company:
set company_id [db_string select_num_clients "select distinct company_id from im_projects where project_id in ([join $in_clause_list ","])"]


# ---------------------------------------------------------------
# Generate SQL Query for the list of tasks (invoicable items)
# ---------------------------------------------------------------


# Invoices: We're only looking for projects with non-invoiced tasks.
# Quotes: We're looking basically for all projects that satisfy the
# filter conditions
if {$target_cost_type_id == [im_cost_type_invoice]} {
    set task_invoice_id_null "and t.invoice_id is null\n"
} else {
    set task_invoice_id_null ""
}

set sql "
select 
	p.project_name,
	p.project_path,
	p.project_path as project_short_name,
	t.task_id,
	t.task_units,
	t.task_name,
	t.billable_units,
	t.task_uom_id,
	t.task_type_id,
	t.project_id,
	im_category_from_id(t.task_uom_id) as uom_name,
	im_category_from_id(t.task_type_id) as type_name,
	im_category_from_id(t.task_status_id) as task_status
from 
	im_trans_tasks t,
	im_projects p
where 
	t.project_id = p.project_id
	$task_invoice_id_null
        and t.task_status_id in (
                select task_status_id
                from im_task_status
                where upper(task_status) not in (
                        'CLOSED','INVOICED','PARTIALLY PAID',
                        'DECLINED','PAID','DELETED','CANCELED'
                )
        )
        $projects_where_clause
order by
	project_id, task_id
"

set task_table "
<tr> 
  <td class=rowtitle align=middle>[im_gif help "Include in Invoice"]</td>
  <td class=rowtitle>[_ intranet-trans-invoices.Task_Name]</td>
  <td class=rowtitle>[_ intranet-trans-invoices.Units]</td>
  <td class=rowtitle>[_ intranet-trans-invoices.Billable_Units]</td>
  <td class=rowtitle>  
    [_ intranet-trans-invoices.UoM] [im_gif help "Unit of Measure"]
  </td>
  <td class=rowtitle>[_ intranet-trans-invoices.Type]</td>
  <td class=rowtitle>[_ intranet-trans-invoices.Status]</td>
</tr>
"

set task_table_rows ""
set ctr 0
set colspan 11
set old_project_id 0
db_foreach select_tasks $sql {

    # insert intermediate headers for every project
    if {$old_project_id != $project_id} {
	append task_table_rows "
		<tr><td colspan=$colspan>&nbsp;</td></tr>
		<tr>
		  <td class=rowtitle colspan=$colspan>
	            <A href=/intranet/projects/view?project_id=$project_id>
		      $project_short_name
		    </A>: 
		    $project_name
		    <input type=hidden name=select_project value=$project_id>
	          </td>
		</tr>\n"
	set old_project_id $project_id
    }

    append task_table_rows "
	<tr $bgcolor([expr $ctr % 2])> 
          <td align=middle>
            <input type=checkbox name=include_task value=$task_id checked>
          </td>
	  <td align=left>$task_name</td>
	  <td align=right>$task_units</td>
	  <td align=right>$billable_units</td>
	  <td align=right>$uom_name</td>
	  <td>$type_name</td>
	  <td>$task_status</td>
	</tr>"
    incr ctr
}

if {![string equal "" $task_table_rows]} {
    append task_table $task_table_rows
} else {
    append task_table "<tr><td colspan=$colspan align=center>[_ intranet-trans-invoices.No_tasks_found]</td></tr>"
}

set deselect_button_html "
    <tr><td colspan=7 align=right>

      <input type=checkbox name=aggregate_tasks_p value=1 $aggregate_tasks_checkbox_enabled>
      [lang::message::lookup "" intranet-trans-invoices.Aggregate_tasks_of_the_same_type "Aggregate tasks of the same type"]

      <input type=submit name=submit value='[_ intranet-trans-invoices.lt_Select_Tasks_for_Invo]'>
    </td></tr>
    <tr><td>&nbsp;</td></tr>
"

# ---------------------------------------------------------------
# 10. Join all parts together
# ---------------------------------------------------------------

set page_body "
[im_costs_navbar "none" "/intranet/invoicing/index" "" "" [list]]

<form action=new-3 method=POST>
[export_form_vars company_id invoice_currency target_cost_type_id return_url]

  <!-- the list of tasks (invoicable items) -->
  <table cellpadding=2 cellspacing=2 border=0>
    $task_table
    $deselect_button_html
  </table>

</form>
"

db_release_unused_handles

ad_return_template