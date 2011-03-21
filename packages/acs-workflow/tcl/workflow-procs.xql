<?xml version="1.0"?>
<queryset>

<fullquery name="wf_task_info.task_roles_to_assign">      
      <querytext>
      
        select r.role_key, 
               r.role_name,
               '' as assignment_widget
          from wf_tasks t, wf_transition_role_assign_map tram, wf_roles r
         where t.task_id = :task_id
           and tram.workflow_key = t.workflow_key and tram.transition_key = t.transition_key
           and r.workflow_key = tram.workflow_key and r.role_key = tram.assign_role_key
        order by r.sort_order
    
      </querytext>
</fullquery>
 
<fullquery name="wf_task_panels.action_panels">      
      <querytext>
      
    select tp.header, 
           tp.template_url
      from wf_context_task_panels tp, 
           wf_cases c,
           wf_tasks t
     where t.task_id = :task_id
       and c.case_id = t.case_id
       and tp.context_key = c.context_key
       and tp.workflow_key = c.workflow_key
       and tp.transition_key = t.transition_key
       and tp.overrides_action_p = 't'
       and (tp.only_display_when_started_p = 'f' or (t.state = 'started' and t.holding_user = :user_id))
    order by tp.overrides_action_p, tp.sort_order

      </querytext>
</fullquery>
 
<fullquery name="wf_task_panels.all_panels">      
      <querytext>
      
    select tp.header, 
           tp.template_url
      from wf_context_task_panels tp, 
           wf_cases c,
           wf_tasks t
     where t.task_id = :task_id
       and c.case_id = t.case_id
       and tp.context_key = c.context_key
       and tp.workflow_key = c.workflow_key
       and tp.transition_key = t.transition_key
       and (tp.only_display_when_started_p = 'f' or (t.state = 'started' and t.holding_user = :user_id))
    order by tp.overrides_action_p, tp.sort_order

      </querytext>
</fullquery>
 
<fullquery name="wf_task_info.this_user_is_assigned_p">      
      <querytext>
       
            select count(*) from wf_user_tasks  where task_id = :task_id and user_id = :user_id
        
      </querytext>
</fullquery>

 
<fullquery name="wf_journal.attributes">      
      <querytext>
      
            select a.attribute_name as name, 
                   a.pretty_name,
                   a.datatype, 
                   v.attr_value as value
            from   wf_attribute_value_audit v, acs_attributes a
            where  v.journal_id = :journal_id
            and    a.attribute_id = v.attribute_id
        
      </querytext>
</fullquery>

 
<fullquery name="wf_workflow_info.workflow">      
      <querytext>
      
        select t.pretty_name,
               w.description
        from   wf_workflows w, acs_object_types t
        where  w.workflow_key = :workflow_key
        and    t.object_type = w.workflow_key
    
      </querytext>
</fullquery>

 
<fullquery name="wf_workflow_info.transitions">      
      <querytext>
      
        select transition_key, transition_name, sort_order
        from wf_transitions 
        where workflow_key = :workflow_key 
        and trigger_type = 'user'
        order by sort_order asc
    
      </querytext>
</fullquery>

 
<fullquery name="wf_journal.attributes">      
      <querytext>
      
            select a.attribute_name as name, 
                   a.pretty_name,
                   a.datatype, 
                   v.attr_value as value
            from   wf_attribute_value_audit v, acs_attributes a
            where  v.journal_id = :journal_id
            and    a.attribute_id = v.attribute_id
        
      </querytext>
</fullquery>

 
<fullquery name="wf_task_action.case_id_from_task">      
      <querytext>
       select case_id from wf_tasks where task_id = :task_id
      </querytext>
</fullquery>

 
<fullquery name="wf_add_place.place_keys">      
      <querytext>
      select place_key from wf_places where workflow_key = :workflow_key
      </querytext>
</fullquery>

 
<fullquery name="wf_add_role.role_keys">      
      <querytext>
      select role_key from wf_roles where workflow_key = :workflow_key
      </querytext>
</fullquery>

 
<fullquery name="wf_add_transition.transition_keys">      
      <querytext>
      select transition_key from wf_transitions where workflow_key = :workflow_key
      </querytext>
</fullquery>

 
<fullquery name="wf_add_transition.estimated_minutes_and_instructions">      
      <querytext>
      
		insert into wf_context_transition_info 
		(context_key, workflow_key, transition_key, estimated_minutes, instructions)
		values (:context_key, :workflow_key, :transition_key, :estimated_minutes, :instructions)
	    
      </querytext>
</fullquery>

 
<fullquery name="wf_export_workflow.workflow_info">      
      <querytext>
      
        select wf.description,
        ot.pretty_name,
        ot.pretty_plural,
        ot.table_name
        from   wf_workflows wf,
        acs_object_types ot
        where  wf.workflow_key = :workflow_key
        and    ot.object_type = wf.workflow_key
    
      </querytext>
</fullquery>

 
<fullquery name="wf_export_workflow.places">      
      <querytext>
      
        select place_key,
               place_name,
               sort_order
        from   wf_places
        where  workflow_key = :workflow_key
        order by sort_order asc
    
      </querytext>
</fullquery>

 
<fullquery name="wf_export_workflow.roles">      
      <querytext>
      
        select role_key,
               role_name,
               sort_order
	from   wf_roles
	where  workflow_key = :workflow_key
    
      </querytext>
</fullquery>

 
<fullquery name="wf_workflow_info.transitions">      
      <querytext>
      
        select transition_key, transition_name, sort_order
        from wf_transitions 
        where workflow_key = :workflow_key 
        and trigger_type = 'user'
        order by sort_order asc
    
      </querytext>
</fullquery>

 
<fullquery name="wf_export_workflow.arcs">      
      <querytext>
      
        select transition_key,
               place_key,
               direction,
               guard_callback,
               guard_custom_arg,
               guard_description
        from   wf_arcs
        where  workflow_key = :workflow_key
        order by transition_key asc
    
      </querytext>
</fullquery>

 
<fullquery name="wf_journal.attributes">      
      <querytext>
      
            select a.attribute_name as name, 
                   a.pretty_name,
                   a.datatype, 
                   v.attr_value as value
            from   wf_attribute_value_audit v, acs_attributes a
            where  v.journal_id = :journal_id
            and    a.attribute_id = v.attribute_id
        
      </querytext>
</fullquery>

 
<fullquery name="wf_export_workflow.transition_attribute_map">      
      <querytext>
      
            select transition_key,
                   sort_order
            from   wf_transition_attribute_map
            where  workflow_key = :workflow_key
            and    attribute_id = :attribute_id
        
      </querytext>
</fullquery>

 
<fullquery name="wf_export_workflow.transition_role_assign_map">      
      <querytext>
      
        select transition_key,
               assign_role_key
          from wf_transition_role_assign_map
         where workflow_key = :workflow_key
         order by transition_key
    
      </querytext>
</fullquery>

 
<fullquery name="wf_export_workflow.context_transition_info">      
      <querytext>
      
        select transition_key,
               estimated_minutes,
               instructions,
               enable_callback,
               enable_custom_arg,
               fire_callback,
               fire_custom_arg,
               time_callback,
               time_custom_arg,
               deadline_callback,
               deadline_custom_arg,
               deadline_attribute_name,
               hold_timeout_callback,
               hold_timeout_custom_arg,
               notification_callback,
               notification_custom_arg,
               unassigned_callback,
               unassigned_custom_arg
        from   wf_context_transition_info
        where  workflow_key = :workflow_key
        and    context_key = :context_key
    
      </querytext>
</fullquery>

 
<fullquery name="wf_export_workflow.context_role_info">      
      <querytext>
      
	select role_key,
	       assignment_callback,
	       assignment_custom_arg
	from   wf_context_role_info
	where  workflow_key = :workflow_key
	and    context_key = :context_key
    
      </querytext>
</fullquery>

 
<fullquery name="wf_export_workflow.context_task_panels">      
      <querytext>
      
        select transition_key,
               sort_order,
               header,
               template_url,
               overrides_action_p,
               overrides_both_panels_p,
               only_display_when_started_p
        from   wf_context_task_panels
        where  context_key = :context_key
        and    workflow_key = :workflow_key
        order by transition_key asc, sort_order asc
    
      </querytext>
</fullquery>
 
</queryset>
