<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="wf_case_info.case">      
      <querytext>
      
        select case_id,
               acs_object.name(object_id) as object_name,
        
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
               acs_object.name(c.object_id) as object_name,
               ot.pretty_name as object_type_pretty,
               c.workflow_key,
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
               acs_object.name(t.holding_user) as holding_user_name,
               p.email as holding_user_email,
               t.hold_timeout,
               to_char(t.hold_timeout, :date_format) as hold_timeout_pretty,
               t.deadline,
               to_char(t.deadline, :date_format) as deadline_pretty,
               t.deadline - sysdate as days_till_deadline,
               tr.estimated_minutes,
               sysdate
          from wf_tasks t, 
               wf_cases c, 
               wf_transition_info tr, 
               acs_objects o, 
               acs_object_types ot, 
               parties p
         where t.task_id = :task_id
           and c.case_id = t.case_id
           and tr.transition_key = t.transition_key
           and tr.workflow_key = t.workflow_key and tr.context_key = c.context_key
           and o.object_id = c.object_id
           and ot.object_type = o.object_type
           and p.party_id (+) = t.holding_user
    
      </querytext>
</fullquery>

 
<fullquery name="wf_task_info.task_attributes_to_set">      
      <querytext>
      
        select a.attribute_id,
               a.attribute_name, 
               a.pretty_name, 
               a.datatype, 
               acs_object.get_attribute(t.case_id, a.attribute_name) as value,
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
               acs_object.name(ut.user_id) as name,
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
               acs_object.name(o.creation_user) as creation_user_name,
               p.email as creation_user_email, 
               o.creation_ip,
               j.msg
        from   journal_entries j, acs_objects o, parties p
        where  j.object_id = :case_id
          and  o.object_id = j.journal_id
          and  p.party_id (+) =  o.creation_user
        order  by o.creation_date $sql_order
    
      </querytext>
</fullquery>

 
<fullquery name="wf_task_action.begin_task_action">      
      <querytext>
      
            begin
                :1 := workflow_case.begin_task_action(
                    task_id => :task_id, 
                    action => :action, 
                    action_ip => :modifying_ip,
                    user_id => :user_id, 
                    msg => :msg);
            end;
        
      </querytext>
</fullquery>

 
<fullquery name="wf_task_action.set_attribute_value">      
      <querytext>
      
                    begin
                        workflow_case.set_attribute_value(
                            journal_id => :journal_id, 
                            attribute_name => :attribute_name, 
                            value => :value
                        );
                    end;
                
      </querytext>
</fullquery>

 
<fullquery name="wf_task_action.clear_assignments">      
      <querytext>
       
                    begin 
                        workflow_case.clear_manual_assignments(
                            case_id => :case_id,
                            role_key => :role_key
                        );
                    end;
                
      </querytext>
</fullquery>

 
<fullquery name="wf_task_action.add_manual_assignment">      
      <querytext>
      
                        begin
                            workflow_case.add_manual_assignment(
                                case_id => :case_id,
                                role_key => :role_key,
                                party_id => :party_id
                            );
                        end;
                    
      </querytext>
</fullquery>

 
<fullquery name="wf_task_action.end_task_action">      
      <querytext>
      
            begin
                workflow_case.end_task_action(
                    journal_id => :journal_id,
                    action => :action,
                    task_id => :task_id
                );
            end;
        
      </querytext>
</fullquery>

 
<fullquery name="wf_message_transition_fire.transition_fire">      
      <querytext>
      
        begin
            workflow_case.fire_message_transition(
                task_id => :task_id
            );
        end;
    
      </querytext>
</fullquery>

 
<fullquery name="wf_case_new.workflow_case_new">      
      <querytext>

      begin 
            :1 := workflow_case.new(case_id => :case_id,
                                    workflow_key => :workflow_key,
                                    context_key => :context_key,
                                    object_id => :object_id,
                                    creation_user => :user_id,
                                    creation_ip => :creation_ip
                                   ); 
      end;

      </querytext>
</fullquery>

 
<fullquery name="wf_case_new.workflow_case_start_case">      
      <querytext>
      begin workflow_case.start_case(case_id => :case_id,
                                     creation_user => :user_id,
                                     creation_ip => :creation_ip
                                    ); end;

      </querytext>
</fullquery>

 
<fullquery name="wf_case_suspend.case_suspend">      
      <querytext>
      
        begin
            workflow_case.suspend(
                case_id => :case_id, 
                user_id => :user_id,
                ip_address => :ip_address,
                msg => :msg
            );
        end;
    
      </querytext>
</fullquery>

 
<fullquery name="wf_case_resume.case_resume">      
      <querytext>
      
        begin
            workflow_case.resume(
                case_id => :case_id, 
                user_id => :user_id,
                ip_address => :ip_address,
                msg => :msg
            );
        end;
    
      </querytext>
</fullquery>

 
<fullquery name="wf_case_cancel.case_cancel">      
      <querytext>
      
        begin
            workflow_case.cancel(
                case_id => :case_id, 
                user_id => :user_id,
                ip_address => :ip_address,
                msg => :msg
            );
        end;
    
      </querytext>
</fullquery>

 
<fullquery name="wf_case_comment.case_comment">      
      <querytext>
      
        begin
            :1 := journal_entry.new(
                object_id => :case_id,
                action => 'comment',
                creation_user => :user_id,
                creation_ip => :ip_address,
                msg => :msg
            );
        end;
    
      </querytext>
</fullquery>

 
<fullquery name="wf_task_action.add_manual_assignment">      
      <querytext>
      
                        begin
                            workflow_case.add_manual_assignment(
                                case_id => :case_id,
                                role_key => :role_key,
                                party_id => :party_id
                            );
                        end;
                    
      </querytext>
</fullquery>

 
<fullquery name="wf_case_remove_manual_assignment.remove_manual_assignment">      
      <querytext>
      
	begin
            workflow_case.remove_manual_assignment(
                case_id  => :case_id,
                role_key => :role_key,
                party_id => :party_id
            );
        end;
    
      </querytext>
</fullquery>

 
<fullquery name="wf_case_clear_manual_assignments.clear_manual_assignments">      
      <querytext>
      
	begin
            workflow_case.clear_manual_assignments(
                case_id  => :case_id,
                role_key => :role_key
            );
        end;
    
      </querytext>
</fullquery>

 
<fullquery name="wf_case_add_task_assignment.add_task_assignment">      
      <querytext>
      
	begin
            workflow_case.add_task_assignment(
                task_id  => :task_id,
                party_id => :party_id,
                permanent_p => :permanent_value
            );
        end;
    
      </querytext>
</fullquery>

 
<fullquery name="wf_case_remove_task_assignment.remove_task_assignment">      
      <querytext>
      
	begin
            workflow_case.remove_task_assignment(
                task_id  => :task_id,
                party_id => :party_id,
                permanent_p => :permanent_value
            );
        end;
    
      </querytext>
</fullquery>

 
<fullquery name="wf_case_clear_task_assignments.clear_task_assignments">      
      <querytext>
      
	begin
            workflow_case.clear_task_assignments(
                task_id  => :task_id,
                permanent_p => :permanent_value
            );
        end;
    
      </querytext>
</fullquery>

 
<fullquery name="wf_case_set_case_deadline.set_case_deadline">      
      <querytext>
      
	begin
            workflow_case.set_case_deadline(
	        case_id => :case_id,
                transition_key => :transition_key,
                deadline => :deadline
            );
        end;
    
      </querytext>
</fullquery>

 
<fullquery name="wf_case_remove_case_deadline.remove_case_deadline">      
      <querytext>
      
	begin
            workflow_case.remove_case_deadline(
	        case_id => :case_id,
                transition_key => :transition_key
            );
        end;
    
      </querytext>
</fullquery>

 
<fullquery name="wf_add_place.wf_add_place">      
      <querytext>
      
        begin
            workflow.add_place(
                workflow_key => :workflow_key,
                place_key => :place_key,
                place_name => :place_name,
                sort_order => :sort_order
            );
        end;
    
      </querytext>
</fullquery>

 
<fullquery name="wf_delete_place.wf_delete_place">      
      <querytext>
      
        begin
            workflow.delete_place(
                workflow_key => :workflow_key,
                place_key => :place_key
            );
        end;
    
      </querytext>
</fullquery>

 
<fullquery name="wf_add_role.wf_add_role">      
      <querytext>
      
	begin
            workflow.add_role(
                workflow_key => :workflow_key,
                role_key => :role_key,
                role_name => :role_name,
                sort_order => :sort_order
            );
        end;
    
      </querytext>
</fullquery>

 
<fullquery name="wf_move_role_up.move_role_up">      
      <querytext>
      
	begin
            workflow.move_role_up(
                workflow_key => :workflow_key,
                role_key => :role_key
            );
        end;
    
      </querytext>
</fullquery>

 
<fullquery name="wf_move_role_down.move_role_down">      
      <querytext>
      
	begin
            workflow.move_role_down(
                workflow_key => :workflow_key,
                role_key => :role_key
            );
        end;
    
      </querytext>
</fullquery>

 
<fullquery name="wf_delete_role.wf_delete_role">      
      <querytext>
      
	begin
            workflow.delete_role(
                workflow_key => :workflow_key,
                role_key => :role_key
            );
        end;
    
      </querytext>
</fullquery>

 
<fullquery name="wf_add_transition.wf_add_transition">      
      <querytext>
      
	    begin
		workflow.add_transition(
		    workflow_key => :workflow_key,
		    transition_key => :transition_key,
		    transition_name => :transition_name,
		    role_key => :role_key,
		    sort_order => :sort_order,
		    trigger_type => :trigger_type
		);
	    end;
	
      </querytext>
</fullquery>

 
<fullquery name="wf_delete_transition.wf_delete_transition">      
      <querytext>
      
	begin
            workflow.delete_transition(
                workflow_key => :workflow_key,
                transition_key => :transition_key
            );
        end;
    
      </querytext>
</fullquery>

 
<fullquery name="wf_add_arc.wf_add_arc">      
      <querytext>
      
        begin
            workflow.add_arc(
                workflow_key => :workflow_key,
	        transition_key => :transition_key,
                place_key => :place_key,
                direction => :direction,
                guard_callback => :guard_callback,
                guard_custom_arg => :guard_custom_arg,
                guard_description => :guard_description
            );
        end;
    
      </querytext>
</fullquery>

 
<fullquery name="wf_add_arc_out.wf_add_arc">      
      <querytext>
      
        begin
            workflow.add_arc(
                workflow_key => :workflow_key,
	        transition_key => :from_transition_key,
                place_key => :to_place_key,
                guard_callback => :guard_callback,
                guard_custom_arg => :guard_custom_arg,
                guard_description => :guard_description
            );
        end;
    
      </querytext>
</fullquery>

 
<fullquery name="wf_add_arc_in.wf_add_arc">      
      <querytext>
      
        begin
            workflow.add_arc(
                workflow_key => :workflow_key,
	        transition_key => :to_transition_key,
                place_key => :from_place_key
            );
        end;
    
      </querytext>
</fullquery>

 
<fullquery name="wf_delete_arc.wf_delete_arc">      
      <querytext>
      
        begin
            workflow.delete_arc(
                workflow_key => :workflow_key,
                transition_key => :transition_key,
                place_key => :place_key,
                direction => :direction
            );
        end;
    
      </querytext>
</fullquery>

 
<fullquery name="wf_add_trans_attribute_map.add_trans_attribute_map_attribute_id">      
      <querytext>
      
	    begin
	        workflow.add_trans_attribute_map(
                    workflow_key => :workflow_key,
	            transition_key => :transition_key,
	            attribute_id => :attribute_id,
	            sort_order => :sort_order
                );
	    end;
	
      </querytext>
</fullquery>

 
<fullquery name="wf_add_trans_attribute_map.add_trans_attribute_map_attribute_name">      
      <querytext>
      
	    begin
	        workflow.add_trans_attribute_map(
                    workflow_key => :workflow_key,
	            transition_key => :transition_key,
	            attribute_name => :attribute_name,
	            sort_order => :sort_order
                );
	    end;
	
      </querytext>
</fullquery>

 
<fullquery name="wf_delete_trans_attribute_map.delete_trans_attribute_map">      
      <querytext>
      
        begin
            workflow.delete_trans_attribute_map(
                workflow_key => :workflow_key,
                transition_key => :transition_key,
                attribute_id => :attribute_id
            );
        end;
    
      </querytext>
</fullquery>

 
<fullquery name="wf_add_trans_role_assign_map.add_trans_role_assign_map">      
      <querytext>
      
        begin
            workflow.add_trans_role_assign_map(
                workflow_key => :workflow_key,
                transition_key => :transition_key,
                assign_role_key => :assign_role_key
            );
        end;
    
      </querytext>
</fullquery>

 
<fullquery name="wf_delete_trans_role_assign_map.delete_trans_role_assign_map">      
      <querytext>
      
        begin
            workflow.delete_trans_role_assign_map(
                workflow_key => :workflow_key,
                transition_key => :transition_key,
                assign_role_key => :assign_role_key
            );
        end;
    
      </querytext>
</fullquery>

 
<fullquery name="wf_simple_workflow_p.simple_workflow">      
      <querytext>
      begin :1 := workflow.simple_p(:workflow_key); end;
      </querytext>
</fullquery>


<partialquery name ="wf_export_workflow.declare_object_type">
        <querytext>
declare
    v_workflow_key varchar2(40);
begin
    v_workflow_key := workflow.create_workflow(
        workflow_key => '[db_quote $new_workflow_key]', 
        pretty_name => '[db_quote $new_workflow_pretty_name]', 
        pretty_plural => '[db_quote $new_workflow_pretty_plural]', 
        description => '[db_quote $description]', 
        table_name => '[db_quote $new_table_name]'
    );
end;
/
show errors

        </querytext>
</partialquery>


<partialquery name ="wf_export_workflow.add_place">
        <querytext>
begin
    workflow.add_place(
        workflow_key => '[db_quote $new_workflow_key]',
        place_key    => '[db_quote $place_key]', 
        place_name   => '[db_quote $place_name]', 
        sort_order   => [ad_decode $sort_order "" "null" $sort_order]
    );
end;
/
show errors 
        </querytext>
</partialquery>



<partialquery name ="wf_export_workflow.add_role">
        <querytext>
begin
    workflow.add_role(
        workflow_key => '[db_quote $new_workflow_key]',
        role_key     => '[db_quote $role_key]',
        role_name    => '[db_quote $role_name]',
        sort_order   => [ad_decode $sort_order "" "null" $sort_order]
    );
end;
/
show errors
        </querytext>
</partialquery>


<partialquery name ="wf_export_workflow.add_transition">
        <querytext>
begin
    workflow.add_transition(
        workflow_key    => '[db_quote $new_workflow_key]',
        transition_key  => '[db_quote $transition_key]',
        transition_name => '[db_quote $transition_name]',
        role_key        => '[db_quote $role_key]',
        sort_order      => [ad_decode $sort_order "" "null" $sort_order],
        trigger_type    => '[db_quote $trigger_type]'
    );
end;
/
show errors
        </querytext>
</partialquery>



<partialquery name ="wf_export_workflow.add_arc">
        <querytext>
begin
    workflow.add_arc(
        workflow_key          => '[db_quote $new_workflow_key]',
        transition_key        => '[db_quote $transition_key]',
        place_key             => '[db_quote $place_key]',
        direction             => '[db_quote $direction]',
        guard_callback        => '[db_quote $guard_callback]',
        guard_custom_arg      => '[db_quote $guard_custom_arg]',
        guard_description     => '[db_quote $guard_description]'
    );
end;
/
show errors
        </querytext>
</partialquery>




<partialquery name ="wf_export_workflow.create_attribute">
        <querytext>
declare
    v_attribute_id number;
begin
    v_attribute_id := workflow.create_attribute(
        workflow_key => '[db_quote $new_workflow_key]',
        attribute_name => '[db_quote $attribute_name]',
        datatype => '[db_quote $datatype]',
        pretty_name => '[db_quote $pretty_name]',
        default_value => '[db_quote $default_value]'
    );
end;
/
show errors
        </querytext>
</partialquery>




<partialquery name ="wf_export_workflow.add_trans_attribute_map">
        <querytext>
begin
    workflow.add_trans_attribute_map(
        workflow_key   => '[db_quote $new_workflow_key]', 
        transition_key => '[db_quote $transition_key]',
        attribute_name => '[db_quote $attribute_name]',
        sort_order     => [ad_decode $sort_order "" "null" $sort_order]
    );
end;
/
show errors
        </querytext>
</partialquery>



<partialquery name ="wf_export_workflow.add_trans_role_assign_map">
        <querytext>
begin
    workflow.add_trans_role_assign_map(
        workflow_key    => '[db_quote $new_workflow_key]',
        transition_key  => '[db_quote $transition_key]',
        assign_role_key => '[db_quote $assign_role_key]'
    );
end;
/
show errors;
        </querytext>
</partialquery>

<fullquery name="wf_sweep_time_events.sweep_timed_transitions">      
      <querytext>
         begin
           workflow_case.sweep_timed_transitions;
         end;
      </querytext>
</fullquery>

<fullquery name="wf_sweep_time_events.sweep_hold_timeout">      
      <querytext>
         begin
           workflow_case.sweep_hold_timeout;
         end;
      </querytext>
</fullquery>

</queryset>








