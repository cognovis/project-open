ad_page_contract {
    Index page for a workflow.

    @author Lars Pind (lars@pinds.com)
    @creation-date November 20, 2000
    @cvs-id $Id$
} {
    workflow_key:notnull
    {tab home}
} -properties {
    workflow:onerow
    context
    edit_process_url
    export_process_url
    edit_attributes_url
    copy_process_url
    return_url
    tab
    modifiable_p
} -validate {
    workflow_exists -requires {workflow_key} {
	if { 0 == [db_string workflow_exists "
	select count(*) from wf_workflows 
	where workflow_key = :workflow_key"] } {
	    ad_complain "You seem to have specified a nonexistent workflow."
	}
    }
}

set user_id [ad_maybe_redirect_for_registration]
set return_url "[ns_conn url]?[export_vars -url {workflow_key tab}]"

db_1row workflow {
    select w.workflow_key, 
           t.pretty_name,
           w.description,
           count(c.case_id) as num_cases,
           0 as num_unassigned_tasks
    from   wf_workflows w, 
           acs_object_types t, 
           wf_cases c
    where  w.workflow_key = :workflow_key 
    and    w.workflow_key = t.object_type
    and    c.workflow_key (+) = w.workflow_key
    group  by w.workflow_key, t.pretty_name, w.description
} -column_array workflow

if { $workflow(num_cases) > 0 } {
    set modifiable_p 0
} else {
    set modifiable_p 1
}

set workflow(num_unassigned_tasks) [db_string num_unassigned_tasks {
    select count(*) 
    from   wf_tasks t,
           wf_cases c
    where  t.workflow_key = :workflow_key
    and    t.state = 'enabled'
    and    c.case_id = t.case_id
    and    c.state = 'active'
    and    not exists (select 1 from wf_task_assignments ta where ta.task_id = t.task_id)
}]

set workflow(num_active_cases) [db_string num_active_cases {
    select count(*) 
    from   wf_cases c
    where  c.workflow_key = :workflow_key
    and    c.state = 'active'
}]

set context [list "$workflow(pretty_name)"]

if { $workflow(num_cases) > 0 } { 
    #set edit_process_url ""
    set edit_process_url "define?[export_vars -url {workflow_key}]"
    set edit_attributes_url ""
    set edit_roles_url "workflow-roles?[export_vars -url {workflow_key}]"
    set copy_process_url "workflow-copy?[export_vars -url {workflow_key}]"
} else {
    set edit_process_url "define?[export_vars -url {workflow_key}]"
    set edit_attributes_url "attributes?[export_vars -url {workflow_key}]"
    set edit_roles_url "workflow-roles?[export_vars -url {workflow_key}]"
    set copy_process_url "workflow-copy?[export_vars -url {workflow_key}]"
}

set export_process_url "export?[export_vars -url {workflow_key}]"

# left navbar
set left_navbar_html ""
set admin_link ""

if { [im_is_user_site_wide_or_intranet_admin $user_id] } {
    set admin_link "<li><a href='/acs-workflow/admin/'> [lang::message::lookup "" acs-workflow.Admin_Workflows "Admin Workflows"]</a></li>"
}

set left_navbar_html "
        <div class='filter-block'>
            <div class='filter-title'>[lang::message::lookup "" acs-workflow.Workflows "Workflows"]</div>
            <ul>
                <li><a href='/intranet-workflow/'>[lang::message::lookup "" acs-workflow.Workflow_Cases "Workflow Cases"]</a></li>
                $admin_link
            </ul>
        </div>
        <hr/>
"

ad_return_template





