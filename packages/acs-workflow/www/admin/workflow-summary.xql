<?xml version="1.0"?>
<queryset>

<fullquery name="workflow_exists">      
      <querytext>
      
	select 1 from wf_workflows 
	where workflow_key = :workflow_key
      </querytext>
</fullquery>

 
<fullquery name="workflow_name">      
      <querytext>
      
    select pretty_name as workflow_name
    from   acs_object_types
    where  object_type = :workflow_key

      </querytext>
</fullquery>

 
<fullquery name="n_total">      
      <querytext>
      
    select count(*) 
    from   wf_cases
    where  workflow_key = :workflow_key

      </querytext>
</fullquery>

 
<fullquery name="num_cases">      
      <querytext>
      
    select state, count(case_id) as num
    from   wf_cases
    where  workflow_key = :workflow_key
    group by state

      </querytext>
</fullquery>

 
<fullquery name="places">      
      <querytext>
      
    select p.place_key, 
           p.place_name,
          (select count(*)
           from   wf_tokens t, wf_cases c
           where  t.workflow_key = p.workflow_key
           and    t.place_key    = p.place_key
           and    t.state in ('free')
           and    c.case_id = t.case_id
           and    c.state = 'active') as num_cases,
           0 as num_pixels,
           '' as cases_url
    from   wf_places p
    where  p.workflow_key = :workflow_key
    order by p.sort_order

      </querytext>
</fullquery>

 
<fullquery name="transitions">      
      <querytext>
      
    select tr.transition_key, 
           tr.transition_name,
	   (select count(*) 
            from   wf_tasks ta, wf_cases c
	    where  ta.workflow_key = tr.workflow_key
	    and    ta.transition_key = tr.transition_key
	    and    ta.state in ('started')
            and    c.case_id = ta.case_id
            and    c.state = 'active') as num_cases,
           0 as num_pixels,
           '' as cases_url
    from   wf_transitions tr
    where  tr.workflow_key = :workflow_key
    order by tr.sort_order

      </querytext>
</fullquery>

 
</queryset>
