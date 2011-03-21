<?xml version="1.0"?>
<queryset>

<fullquery name="all_workflows">      
      <querytext>

    select w.workflow_key, 
           t.pretty_name,
           w.description,
           count(c.case_id) as num_cases,
           0 as num_unassigned_tasks
    from   wf_workflows w left outer join wf_cases c
             on (w.workflow_key = c.workflow_key and c.state = 'active'),
           acs_object_types t
    where  w.workflow_key = t.object_type
    group  by w.workflow_key, t.pretty_name, w.description
    order  by t.pretty_name

      </querytext>
</fullquery>

 
<fullquery name="num_unassigned_tasks">      
      <querytext>
      
	select count(*) 
	from   wf_tasks t, wf_cases c
	where  t.workflow_key = :workflow_key
	and    t.state = 'enabled'
        and    c.case_id = t.case_id
        and    c.state = 'active'
	and    not exists (select 1 from wf_task_assignments ta where ta.task_id = t.task_id)
    
      </querytext>
</fullquery>

 
</queryset>
