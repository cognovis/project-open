<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="wf_case_info.case">      
      <querytext>
      
        select case_id,
               acs_object__name(object_id) as object_name,
        
               state
        from   wf_cases
        where  case_id = :case_id
    
      </querytext>
</fullquery>

 
<fullquery name="wf_task_info.task">      
      <querytext>

        select t.task_id,
               t.case_id, 
               c.object_id,
               acs_object__name(c.object_id) as object_name,
               ot.pretty_name as object_type_pretty,
               c.workflow_key,
	       tr.transition_key,
               tr.transition_name as task_name, 
               tr.instructions,
               t.state, 
               t.enabled_date,
               to_char(t.enabled_date, :date_format) as enabled_date_pretty,
               t.started_date,
               to_char(t.started_date, :date_format) as started_date_pretty,
               t.canceled_date,
               to_char(t.canceled_date, :date_format) as canceled_date_pretty,
               t.finished_date,
               to_char(t.finished_date, :date_format) as finished_date_pretty,
               t.overridden_date,
               to_char(t.overridden_date, :date_format) as overridden_date_pretty,
               t.holding_user, 
               acs_object__name(t.holding_user) as holding_user_name,
               p.email as holding_user_email,
               t.hold_timeout,
               to_char(t.hold_timeout, :date_format) as hold_timeout_pretty,
               t.deadline,
               to_char(t.deadline, :date_format) as deadline_pretty,
               t.deadline - current_timestamp as days_till_deadline,
               tr.estimated_minutes,
               current_timestamp
          from wf_tasks t left outer join parties p 
                on p.party_id = t.holding_user,
               wf_cases c, 
               wf_transition_info tr, 
               acs_objects o, 
               acs_object_types ot
         where t.task_id = :task_id
           and c.case_id = t.case_id
           and tr.transition_key = t.transition_key
           and tr.workflow_key = t.workflow_key and tr.context_key = c.context_key
           and o.object_id = c.object_id
           and ot.object_type = o.object_type
    
      </querytext>
</fullquery>


<fullquery name="wf_task_info.task_attributes_to_set">      
      <querytext>
      
        select a.attribute_id,
               a.attribute_name, 
               a.pretty_name, 
               a.datatype, 
               acs_object__get_attribute(t.case_id, a.attribute_name) as value,
               '' as attribute_widget
          from acs_attributes a, wf_transition_attribute_map m, wf_tasks t
         where t.task_id = :task_id
           and m.workflow_key = t.workflow_key and m.transition_key = t.transition_key
           and a.attribute_id = m.attribute_id
         order by m.sort_order
    
      </querytext>
</fullquery>

 
<fullquery name="wf_task_info.task_assigned_users">      
      <querytext>
      
        select ut.user_id,
               acs_object__name(ut.user_id) as name,
               p.email as email
          from wf_user_tasks ut, parties p
         where ut.task_id = :task_id
           and p.party_id = ut.user_id
    
      </querytext>
</fullquery>

 
<fullquery name="wf_journal.journal">      
      <querytext>

        select j.journal_id,
               j.action,
               j.action_pretty,
               o.creation_date,
               to_char(o.creation_date, :date_format) as creation_date_pretty,
               o.creation_user,
               acs_object__name(o.creation_user) as creation_user_name,
               p.email as creation_user_email, 
               o.creation_ip,
               j.msg
        from   journal_entries j, acs_objects o left outer join parties p
                on p.party_id =  o.creation_user
        where  j.object_id = :case_id
          and  o.object_id = j.journal_id
        order  by o.creation_date $sql_order
    
      </querytext>
</fullquery>

 
<fullquery name="wf_task_action.begin_task_action">      
      <querytext>
 
                select workflow_case__begin_task_action (
                    :task_id, 
                    :action, 
                    :modifying_ip,
                    :user_id, 
                    :msg);
        
      </querytext>
</fullquery>

 
<fullquery name="wf_task_action.set_attribute_value">      
      <querytext>

		select workflow_case__set_attribute_value (
                            :journal_id, 
                            :attribute_name, 
                            :value
                        );
                
      </querytext>
</fullquery>

 
<fullquery name="wf_task_action.clear_assignments">      
      <querytext>
		select workflow_case__clear_manual_assignments (
                            :case_id,
                            :role_key
                        );
                
      </querytext>
</fullquery>


<fullquery name="wf_task_action.add_manual_assignment">      
      <querytext>

	select workflow_case__add_manual_assignment (
                                :case_id,
                                :role_key,
                                :party_id
                            );
                    
      </querytext>
</fullquery>

 
<fullquery name="wf_task_action.end_task_action">      
      <querytext>

		select workflow_case__end_task_action (
                    :journal_id,
                    :action,
                    :task_id
                );
        
      </querytext>
</fullquery>

 
<fullquery name="wf_message_transition_fire.transition_fire">      
      <querytext>

	select workflow_case__fire_message_transition (
                :task_id
            );
    
      </querytext>
</fullquery>

 
<fullquery name="wf_case_new.workflow_case_new">      
      <querytext>
      select workflow_case__new (
		:case_id,
                :workflow_key,
                :context_key,
                :object_id,
                now(),
                :user_id,
                :creation_ip
             );
      </querytext>
</fullquery>

 
<fullquery name="wf_case_new.workflow_case_start_case">      
      <querytext>
      select workflow_case__start_case (
		:case_id,
                :user_id,
                :creation_ip,
                null
             );

      </querytext>
</fullquery>

 
<fullquery name="wf_case_suspend.case_suspend">      
      <querytext>
      
        select workflow_case__suspend (
                :case_id, 
                :user_id,
                :ip_address,
                :msg
            );
        
      </querytext>
</fullquery>

 
<fullquery name="wf_case_resume.case_resume">      
      <querytext>
      
        select workflow_case__resume (
                :case_id, 
                :user_id,
                :ip_address,
                :msg
            );
    
      </querytext>
</fullquery>

 
<fullquery name="wf_case_cancel.case_cancel">      
      <querytext>
      
        select workflow_case__cancel (
                :case_id, 
                :user_id,
                :ip_address,
                :msg
            );
        
      </querytext>
</fullquery>

 
<fullquery name="wf_case_comment.case_comment">      
      <querytext>

            select journal_entry__new (
                null,
                :case_id,
                'comment',
                null,
                now(),
                :user_id,
                :ip_address,
                :msg
            )
    
      </querytext>
</fullquery>

 
<fullquery name="wf_case_add_manual_assignment.add_manual_assignment">      
      <querytext>
		select workflow_case__add_manual_assignment (
                                :case_id,
                                :role_key,
                                :party_id
                            );
                    
      </querytext>
</fullquery>

 
<fullquery name="wf_case_remove_manual_assignment.remove_manual_assignment">      
      <querytext>

	select workflow_case__remove_manual_assignment (
                :case_id,
                :role_key,
                :party_id
            );
    
      </querytext>
</fullquery>

 
<fullquery name="wf_case_clear_manual_assignments.clear_manual_assignments">      
      <querytext>

	select workflow_case__clear_manual_assignments (
                :case_id,
                :role_key
            );
    
      </querytext>
</fullquery>

 
<fullquery name="wf_case_add_task_assignment.add_task_assignment">      
      <querytext>

	select workflow_case__add_task_assignment (
                :task_id,
                :party_id,
                :permanent_value
            );
    
      </querytext>
</fullquery>

 
<fullquery name="wf_case_remove_task_assignment.remove_task_assignment">      
      <querytext>

	select workflow_case__remove_task_assignment (
                :task_id,
                :party_id,
                :permanent_value
            );
    
      </querytext>
</fullquery>

 
<fullquery name="wf_case_clear_task_assignments.clear_task_assignments">      
      <querytext>

	select workflow_case__clear_task_assignments (
                :task_id,
                :permanent_value
            );
    
      </querytext>
</fullquery>

 
<fullquery name="wf_case_set_case_deadline.set_case_deadline">      
      <querytext>

	select workflow_case__set_case_deadline (
	        :case_id,
                :transition_key,
                :deadline
            );
    
      </querytext>
</fullquery>

 
<fullquery name="wf_case_remove_case_deadline.remove_case_deadline">      
      <querytext>

	select workflow_case__remove_case_deadline (
	        :case_id,
                :transition_key
            );
    
      </querytext>
</fullquery>

 
<fullquery name="wf_add_place.wf_add_place">      
      <querytext>

	select workflow__add_place (
                :workflow_key,
                :place_key,
                :place_name,
                :sort_order
            );
    
      </querytext>
</fullquery>

 
<fullquery name="wf_delete_place.wf_delete_place">      
      <querytext>
 
	select workflow__delete_place (
                :workflow_key,
                :place_key
            );
    
      </querytext>
</fullquery>

 
<fullquery name="wf_add_role.wf_add_role">      
      <querytext>

	select workflow__add_role (
                :workflow_key,
                :role_key,
                :role_name,
                :sort_order
            );
    
      </querytext>
</fullquery>

 
<fullquery name="wf_move_role_up.move_role_up">      
      <querytext>

	select workflow__move_role_up (
                :workflow_key,
                :role_key
            );
    
      </querytext>
</fullquery>

 
<fullquery name="wf_move_role_down.move_role_down">      
      <querytext>

	select workflow__move_role_down (
                :workflow_key,
                :role_key
            );
    
      </querytext>
</fullquery>

 
<fullquery name="wf_delete_role.wf_delete_role">      
      <querytext>

	select workflow__delete_role (
                :workflow_key,
                :role_key
            );
    
      </querytext>
</fullquery>

 
<fullquery name="wf_add_transition.wf_add_transition">      
      <querytext>

	select workflow__add_transition (
		    :workflow_key,
		    :transition_key,
		    :transition_name,
		    :role_key,
		    :sort_order,
		    :trigger_type
		);
	
      </querytext>
</fullquery>

 
<fullquery name="wf_delete_transition.wf_delete_transition">      
      <querytext>

	select workflow__delete_transition (
                :workflow_key,
                :transition_key
            );
    
      </querytext>
</fullquery>

 
<fullquery name="wf_add_arc.wf_add_arc">      
      <querytext>

	select workflow__add_arc (
                :workflow_key,
	        :transition_key,
                :place_key,
                :direction,
                :guard_callback,
                :guard_custom_arg,
                :guard_description
            );
    
      </querytext>
</fullquery>

 
<fullquery name="wf_add_arc_out.wf_add_arc">      
      <querytext>

	select workflow__add_arc (
                :workflow_key,
	        :from_transition_key,
                :to_place_key,
                :guard_callback,
                :guard_custom_arg,
                :guard_description
            );
    
      </querytext>
</fullquery>

 
<fullquery name="wf_add_arc_in.wf_add_arc">      
      <querytext>

	select workflow__add_arc (
                :workflow_key,
                :from_place_key,
	        :to_transition_key
            );

      </querytext>
</fullquery>

 
<fullquery name="wf_delete_arc.wf_delete_arc">      
      <querytext>

	select workflow__delete_arc (
                :workflow_key,
                :transition_key,
                :place_key,
                :direction
            );
    
      </querytext>
</fullquery>

 
<fullquery name="wf_add_trans_attribute_map.add_trans_attribute_map_attribute_id">      
      <querytext>

	select workflow__add_trans_attribute_map (
                    :workflow_key,
	            :transition_key,
	            :attribute_id,
	            :sort_order
                );
	
      </querytext>
</fullquery>

 
<fullquery name="wf_add_trans_attribute_map.add_trans_attribute_map_attribute_name">      
      <querytext>

	select workflow__add_trans_attribute_map (
                    :workflow_key,
	            :transition_key,
	            :attribute_name,
	            :sort_order
                );
	
      </querytext>
</fullquery>

 
<fullquery name="wf_delete_trans_attribute_map.delete_trans_attribute_map">      
      <querytext>

	select workflow__delete_trans_attribute_map (
                :workflow_key,
                :transition_key,
                :attribute_id
            );
    
      </querytext>
</fullquery>

 
<fullquery name="wf_add_trans_role_assign_map.add_trans_role_assign_map">      
      <querytext>

	select workflow__add_trans_role_assign_map (
                :workflow_key,
                :transition_key,
                :assign_role_key
            );
    
      </querytext>
</fullquery>

 
<fullquery name="wf_delete_trans_role_assign_map.delete_trans_role_assign_map">      
      <querytext>

	select workflow__delete_trans_role_assign_map (
                :workflow_key,
                :transition_key,
                :assign_role_key
            );
    
      </querytext>
</fullquery>

 
<fullquery name="wf_simple_workflow_p.simple_workflow">      
      <querytext>
	select workflow__simple_p(:workflow_key);
      </querytext>
</fullquery>


<partialquery name ="wf_export_workflow.declare_object_type">
        <querytext>

create function inline_0 () returns integer as '
begin
    PERFORM workflow__create_workflow (
        ''[db_quote [db_quote $new_workflow_key]]'', 
        ''[db_quote [db_quote $new_workflow_pretty_name]]'', 
        ''[db_quote [db_quote $new_workflow_pretty_plural]]'', 
        ''[db_quote [db_quote $description]]'', 
        ''[db_quote [db_quote $new_table_name]]'',
        ''case_id''
    );

    return null;

end;' language 'plpgsql';

select inline_0 ();
drop function inline_0 ();

        </querytext>
</partialquery>


<partialquery name ="wf_export_workflow.add_place">
        <querytext>

    select workflow__add_place(
        '[db_quote $new_workflow_key]',
        '[db_quote $place_key]', 
        '[db_quote $place_name]', 
        [ad_decode $sort_order "" "null" $sort_order]
    );

        </querytext>
</partialquery>

<partialquery name ="wf_export_workflow.add_role">
        <querytext>

	select workflow__add_role (
         '[db_quote $new_workflow_key]',
         '[db_quote $role_key]',
         '[db_quote $role_name]',
         [ad_decode $sort_order "" "null" $sort_order]
    );

        </querytext>
</partialquery>


<partialquery name ="wf_export_workflow.add_transition">
        <querytext>

	select workflow__add_transition (
         '[db_quote $new_workflow_key]',
         '[db_quote $transition_key]',
         '[db_quote $transition_name]',
         [ad_decode $role_key "" null '[db_quote $role_key]'],
         [ad_decode $sort_order "" "null" $sort_order],
         '[db_quote $trigger_type]'
	);
	
        </querytext>
</partialquery>


<partialquery name ="wf_export_workflow.add_arc">
        <querytext>

	select workflow__add_arc (
         '[db_quote $new_workflow_key]',
         '[db_quote $transition_key]',
         '[db_quote $place_key]',
         '[db_quote $direction]',
         '[db_quote $guard_callback]',
         '[db_quote $guard_custom_arg]',
         '[db_quote $guard_description]'
	);

        </querytext>
</partialquery>


<partialquery name ="wf_export_workflow.create_attribute">
        <querytext>

    select workflow__create_attribute(
        '[db_quote $new_workflow_key]',
        '[db_quote $attribute_name]',
        '[db_quote $datatype]',
        '[db_quote $pretty_name]',
	null,
	null,
	null,
        '[db_quote $default_value]',
	1,
	1,
	null,
	'generic'
    );

        </querytext>
</partialquery>




<partialquery name ="wf_export_workflow.add_trans_attribute_map">
        <querytext>

	select workflow__add_trans_attribute_map(
        	'[db_quote $new_workflow_key]', 
        	'[db_quote $transition_key]',
        	'[db_quote $attribute_name]',
        	[ad_decode $sort_order "" "null" $sort_order]
    );

        </querytext>
</partialquery>


<partialquery name ="wf_export_workflow.add_trans_role_assign_map">
        <querytext>

    select workflow__add_trans_role_assign_map(
        '[db_quote $new_workflow_key]',
        '[db_quote $transition_key]',
        '[db_quote $assign_role_key]'
    );

        </querytext>
</partialquery>

<fullquery name="wf_sweep_time_events.sweep_timed_transitions">      
      <querytext>
         select workflow_case__sweep_timed_transitions();
      </querytext>
</fullquery>

<fullquery name="wf_sweep_time_events.sweep_hold_timeout">      
      <querytext>
         select workflow_case__sweep_hold_timeout();
      </querytext>
</fullquery>


</queryset>
