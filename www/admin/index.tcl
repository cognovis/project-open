ad_page_contract {
    Admin index page.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 25 September 2000
    @cvs-id $Id$
} -properties {
    context 
    workflows
    actions:multirow
}

set context [list]

db_multirow workflows all_workflows {
    select w.workflow_key, 
           t.pretty_name,
           w.description,
           count(c.case_id) as num_cases,
           0 as num_unassigned_tasks
    from   wf_workflows w, 
           acs_object_types t, 
           wf_cases c
    where  w.workflow_key = t.object_type
    and    c.workflow_key (+) = w.workflow_key
    and    c.state (+) = 'active'
    group  by w.workflow_key, t.pretty_name, w.description
    order  by t.pretty_name
} {
    set num_unassigned_tasks [db_string num_unassigned_tasks {
	select count(*) 
	from   wf_tasks t, wf_cases c
	where  t.workflow_key = :workflow_key
	and    t.state = 'enabled'
        and    c.case_id = t.case_id
        and    c.state = 'active'
	and    not exists (select 1 from wf_task_assignments ta where ta.task_id = t.task_id)
    }]
    set workflow_key [ns_urlencode $workflow_key]
    set pretty_name [ad_quotehtml $pretty_name]
}

template::multirow create actions url title
template::multirow append actions "wizard/" "New Simple Process"
template::multirow append actions "workflow-add" "New Advanced Process"

ad_return_template 
