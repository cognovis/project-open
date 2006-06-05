<?xml version="1.0"?>
<queryset>

<fullquery name="workflow_exists">      
      <querytext>
      
	select count(*) from wf_workflows 
	where workflow_key = :workflow_key
      </querytext>
</fullquery>

 
<fullquery name="workflow">      
      <querytext>

    select w.workflow_key, 
           t.pretty_name,
           w.description,
           count(c.case_id) as num_cases,
           0 as num_unassigned_tasks
    from   wf_workflows w left outer join wf_cases c using (workflow_key),
           acs_object_types t
    where  w.workflow_key = :workflow_key 
    and    w.workflow_key = t.object_type
    group  by w.workflow_key, t.pretty_name, w.description

      </querytext>
</fullquery>

 
<fullquery name="num_unassigned_tasks">      
      <querytext>
      
    select count(*) 
    from   wf_tasks t,
           wf_cases c
    where  t.workflow_key = :workflow_key
    and    t.state = 'enabled'
    and    c.case_id = t.case_id
    and    c.state = 'active'
    and    not exists (select 1 from wf_task_assignments ta where ta.task_id = t.task_id)

      </querytext>
</fullquery>

 
<fullquery name="num_active_cases">      
      <querytext>
      
    select count(*) 
    from   wf_cases c
    where  c.workflow_key = :workflow_key
    and    c.state = 'active'

      </querytext>
</fullquery>

 
</queryset>
