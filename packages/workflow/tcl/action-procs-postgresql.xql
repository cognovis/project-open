<?xml version="1.0"?>
<queryset>
  <rdbms><type>postgresql</type><version>7.2</version></rdbms>

  <partialquery name="workflow::action::edit.update_timeout_seconds_name">
    <querytext>
      timeout
    </querytext>
  </partialquery>

  <partialquery name="workflow::action::edit.update_timeout_seconds_value">
    <querytext>
      [ad_decode $attr_timeout_seconds "" "null" "interval '$attr_timeout_seconds seconds'"]
    </querytext>
  </partialquery>

  <fullquery name="workflow::action::get_all_info_not_cached.action_info">
    <querytext>
        select a.action_id,
               a.workflow_id,
               a.sort_order,
               a.short_name,
               a.pretty_name,
               a.pretty_past_tense,
               a.edit_fields,
               a.trigger_type,
               a.parent_action_id,
               (select short_name from workflow_actions where action_id = a.parent_action_id) as parent_action,
               a.assigned_role as assigned_role_id,
               (select short_name from workflow_roles where role_id = a.assigned_role) as assigned_role,
               a.always_enabled_p,
               fa.new_state as new_state_id,
               (select short_name from workflow_fsm_states where state_id = fa.new_state) as new_state,
               a.description,
               a.description_mime_type,
               extract (days from a.timeout) * 86400 + extract (hours from a.timeout) * 3600 + 
                 extract (minutes from a.timeout) * 60 + extract (seconds from a.timeout) as timeout_seconds
        from   workflow_actions a left outer join 
               workflow_fsm_actions fa on (a.action_id = fa.action_id) 
        where  a.workflow_id = :workflow_id
        order by a.sort_order
    </querytext>
 </fullquery>
 
  <fullquery name="workflow::action::callback_insert.select_sort_order">
    <querytext>
        select coalesce(max(sort_order),0) + 1
        from   workflow_action_callbacks
        where  action_id = :action_id
    </querytext>
  </fullquery>

  <fullquery name="workflow::action::edit.insert_allowed_role">
    <querytext>
        insert into workflow_action_allowed_roles
        select :action_id,
                (select role_id
                from workflow_roles
                where workflow_id = :workflow_id
                and short_name = :allowed_role) as role_id
    </querytext>
  </fullquery>


</queryset>
