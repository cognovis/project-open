<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="workflow">      
      <querytext>
      
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

      </querytext>
</fullquery>

 
</queryset>
