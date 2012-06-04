ad_page_contract {
    List unassigned tasks

    @author Lars Pind (lars@pinds.com)
    @creation-date November 1, 2000
    @cvs-id $Id$
} {
    workflow_key
} -properties {
    workflow:onerow
    context
    tasks:multirow
}

db_1row workflow_info {
    select  ot.pretty_name
    from    wf_workflows wf, acs_object_types ot
    where   wf.workflow_key = :workflow_key
    and     ot.object_type = wf.workflow_key
} -column_array workflow

set workflow(workflow_key) $workflow_key

set context [list [list "workflow?[export_url_vars workflow_key]" "$workflow(pretty_name)"] "Unassigned tasks"]

set date_format "Mon fmDDfm, YYYY HH24:MI:SS"

db_multirow tasks unassigned_tasks {
    select ta.task_id,
           ta.case_id,
           ta.workflow_key,
           ta.transition_key,             
           tr.transition_name,
           ta.enabled_date,
           to_char(ta.enabled_date, :date_format) enabled_date_pretty,
           ta.state,
           ta.deadline,
           to_char(ta.deadline, :date_format) as deadline_pretty,
           ta.estimated_minutes,
           c.object_id,
           acs_object.name(c.object_id) as object_name,
           o.object_type
    from   wf_tasks ta, wf_transitions tr, wf_cases c, acs_objects o
    where  ta.workflow_key = :workflow_key
    and    tr.workflow_key = ta.workflow_key
    and    tr.transition_key = ta.transition_key
    and    c.case_id = ta.case_id
    and    o.object_id = c.object_id
    and    ta.state = 'enabled'
    and    not exists (select 1 from wf_task_assignments tasgn where tasgn.task_id = ta.task_id)
}

ad_return_template
