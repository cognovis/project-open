<?xml version="1.0"?>
<queryset>

  <fullquery name="workflow::case::insert.select_initial_state">
    <querytext>
      select state_id
      from   workflow_fsm_states
      where  workflow_id = :workflow_id
      order  by sort_order
      limit  1
    </querytext>
  </fullquery>

  <fullquery name="workflow::case::insert.insert_case">
    <querytext>
      insert into workflow_cases (
        case_id, workflow_id, object_id
      ) values (
        :case_id, :workflow_id, :object_id
      )      
    </querytext>
  </fullquery>

  <fullquery name="workflow::case::insert.insert_case_fsm">
    <querytext>
      insert into workflow_case_fsm (
        case_id, parent_enabled_action_id, current_state
      ) values (
        :case_id, null, null
      )
    </querytext>
  </fullquery>

  <fullquery name="workflow::case::get_id.select_case_id">
    <querytext>
      select case_id
      from   workflow_cases c, 
             workflows w
      where  c.object_id = :object_id
      and    w.workflow_id = c.workflow_id
      and    w.short_name = :workflow_short_name
    </querytext>
  </fullquery>

  <fullquery name="workflow::case::get_user_roles_not_cached.select_user_roles">
    <querytext>
      select distinct role_id
      from   workflow_case_role_user_map
      where  case_id = :case_id
      and    user_id = :user_id
    </querytext>
  </fullquery>

  <fullquery name="workflow::case::get_enabled_actions_not_cached.select_enabled_actions">
    <querytext>
      select a.action_id
      from   workflow_case_enabled_actions ena,
             workflow_actions a
      where  ena.case_id = :case_id
      and    a.action_id = ena.action_id
      and    ena.completed_p = 'f'
      and    a.trigger_type = 'user'
      order by a.sort_order
    </querytext>
  </fullquery>

  <fullquery name="workflow::case::assign_roles.select_num_assignees">
    <querytext>
      select count(*)
      from   workflow_case_role_user_map
      where  case_id = :case_id
      and    role_id = :role_id
    </querytext>
  </fullquery>

  <fullquery name="workflow::case::add_log_data.insert_log_data">
    <querytext>
      insert into workflow_case_log_data
        (entry_id, key, value)
      values
        (:entry_id, :key, :value)
    </querytext>
  </fullquery>

  <fullquery name="workflow::case::get_log_data_by_key.select_log_data">
    <querytext>
      select value
      from   workflow_case_log_data
      where  entry_id = :entry_id
      and    key = :key
    </querytext>
  </fullquery>

  <fullquery name="workflow::case::get_log_data.select_log_data">
    <querytext>
      select key, value
      from   workflow_case_log_data
      where  entry_id = :entry_id
      order  by key
    </querytext>
  </fullquery>


  <fullquery name="workflow::case::state_changed_handler.select_previously_enabled_actions">
    <querytext>
      select ena.action_id,
             ena.enabled_action_id
      from   workflow_case_enabled_actions ena
      where  ena.case_id = :case_id
      and    parent_enabled_action_id = :parent_enabled_action_id
    </querytext>
  </fullquery>

  <fullquery name="workflow::case::state_changed_handler.select_previously_enabled_actions_null_parent">
    <querytext>
      select ena.action_id,
             ena.enabled_action_id
      from   workflow_case_enabled_actions ena
      where  ena.case_id = :case_id
      and    parent_enabled_action_id is null
    </querytext>
  </fullquery>

  <fullquery name="workflow::case::role::get_callbacks.select_callbacks">
    <querytext>
      select impl.impl_name
      from   workflow_role_callbacks r,
             acs_sc_impls impl,
             acs_sc_bindings bind,
             acs_sc_contracts ctr
      where  r.role_id = :role_id
      and    impl.impl_id = r.acs_sc_impl_id
      and    impl.impl_id = bind.impl_id
      and    bind.contract_id = ctr.contract_id
      and    ctr.contract_name = :contract_name
      order  by r.sort_order
    </querytext>
  </fullquery>

  <fullquery name="workflow::case::role::assignee_insert.delete_assignees">
    <querytext>
        delete from workflow_case_role_party_map
        where  case_id = :case_id
        and    role_id = :role_id
    </querytext>
  </fullquery>

  <fullquery name="workflow::case::role::assignee_remove.delete_assignee">
    <querytext>
        delete from workflow_case_role_party_map
        where  case_id = :case_id
        and    role_id = :role_id
        and    party_id = :party_id
    </querytext>
  </fullquery>

  <fullquery name="workflow::case::role::assignee_insert.insert_assignee">
    <querytext>
      insert into workflow_case_role_party_map
        (case_id, role_id, party_id)
      values
        (:case_id, :role_id, :party_id)
    </querytext>
  </fullquery>

  <fullquery name="workflow::case::role::assignee_insert.already_assigned_p">
    <querytext>
      select count(*)
      from   workflow_case_role_party_map
      where  case_id = :case_id
      and    role_id = :role_id
      and    party_id = :party_id
    </querytext>
  </fullquery>

  <fullquery name="workflow::case::fsm::get_current_state.select_current_state">
    <querytext>
      select current_state
      from   workflow_case_fsm c
      where  c.case_id = :case_id
      and    c.parent_enabled_action_id is null
    </querytext>
  </fullquery>

  <fullquery name="workflow::case::fsm::get.select_case_info_after_action">
    <querytext>
      select c.case_id,
             c.workflow_id,
             c.object_id,
             s.state_id,
             s.short_name as state_short_name,
             s.pretty_name as pretty_state,
             s.hide_fields as state_hide_fields
      from   workflow_cases c,
             workflow_case_fsm cfsm,
             workflow_fsm_states s,
             workflow_fsm_actions afsm,
             workflow_case_enabled_actions ena
      where  c.case_id = :case_id
      and    cfsm.case_id = c.case_id
      and    ((:parent_enabled_action_id is null and cfsm.parent_enabled_action_id is null) or (cfsm.parent_enabled_action_id = :parent_enabled_action_id))
      and    ena.enabled_action_id = :enabled_action_id
      and    afsm.action_id = ena.action_id
      and    ((afsm.new_state is null and s.state_id = cfsm.current_state)  or (s.state_id = afsm.new_state))
    </querytext>
  </fullquery>

  <fullquery name="workflow::case::action::execute.log_entry_exists_p">
    <querytext>
        select count(*)
        from   cr_items
        where  item_id = :entry_id
    </querytext>
  </fullquery>
  <fullquery name="workflow::case::action::notify.enabled_action_assignees">
    <querytext>
        select distinct rum.user_id
        from   workflow_cases c,
               workflow_actions a,
               workflow_case_role_user_map rum 
        where  c.case_id = :case_id
        and    a.workflow_id = c.workflow_id
        and    (a.always_enabled_p = 't' or 
                exists (select 1 
                        from   workflow_fsm_action_en_in_st waeis,
                               workflow_case_fsm c_fsm
                        where  waeis.action_id = a.action_id
                        and    c_fsm.case_id = c.case_id
                        and    waeis.state_id = c_fsm.current_state)
               )
        and    rum.case_id = c.case_id
        and    rum.role_id = a.assigned_role
    </querytext>
  </fullquery>

  <fullquery name="workflow::case::action::notify.case_players">
    <querytext>
        select distinct user_id
        from   workflow_case_role_user_map
        where  case_id = :case_id
    </querytext>
  </fullquery>

  <fullquery name="workflow::case::action::notify.select_object_type_info">
    <querytext>
        select lower(pretty_name) as pretty_name,
               lower(pretty_plural) as pretty_plural
        from   acs_object_types ot,
               acs_objects o
        where  o.object_id = :object_id
        and    ot.object_type = o.object_type
    </querytext>
  </fullquery>

  <fullquery name="workflow::case::fsm::get_state_info_not_cached.select_state_info">
    <querytext>
      select cfsm.parent_enabled_action_id,
             cfsm.current_state as current_state_id
      from   workflow_case_fsm cfsm 
      where  cfsm.case_id = :case_id
    </querytext>
  </fullquery>

</queryset>
