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
set max_description 200
set ctr 1
db_multirow  -extend {row_even_p} workflows all_workflows {
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
    set description [string range $description 0 [expr $max_description-1]]
    if {$max_description == [string length $description]} { append description "..." }
    set num_unassigned_tasks [db_string num_unassigned_tasks {
	select count(*) 
	from   wf_tasks t, wf_cases c
	where  t.workflow_key = :workflow_key
	and    t.state = 'enabled'
        and    c.case_id = t.case_id
        and    c.state = 'active'
	and    not exists (select 1 from wf_task_assignments ta where ta.task_id = t.task_id)
    }]
    set pretty_name [ad_quotehtml $pretty_name]

    set row_even_p [expr $ctr % 2]
    incr ctr
}

template::multirow create actions url title
template::multirow append actions "wizard/" "New Simple Process"
template::multirow append actions "workflow-add" "New Advanced Process"

ad_return_template 
