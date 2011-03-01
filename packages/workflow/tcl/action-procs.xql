<?xml version="1.0"?>
<queryset>

  <fullquery name="workflow::action::update_sort_order.select_sort_order_p">
    <querytext>
        select count(*)
        from   workflow_actions
        where  workflow_id = :workflow_id
        and    sort_order = :sort_order
    </querytext>
  </fullquery>

  <fullquery name="workflow::action::update_sort_order.update_sort_order">
    <querytext>
        update workflow_actions
        set    sort_order = sort_order + 1
        where  workflow_id = :workflow_id
        and    sort_order >= :sort_order
    </querytext>
  </fullquery>

  <fullquery name="workflow::action::edit.insert_privilege">
    <querytext>
        insert into workflow_action_privileges
                (action_id, privilege)
         values (:action_id, :privilege)
    </querytext>
  </fullquery>

  <fullquery name="workflow::action::edit.insert_initial_action">
    <querytext> 
        insert into workflow_initial_action
                (workflow_id, action_id)
         values (:workflow_id, :action_id)
    </querytext>
  </fullquery>

  <fullquery name="workflow::action::get_all_info_not_cached.select_privileges">
    <querytext>
      select p.privilege,
             p.action_id
      from   workflow_action_privileges p,
             workflow_actions a
      where  a.action_id = p.action_id
        and  a.workflow_id = :workflow_id
      order  by privilege
    </querytext>
  </fullquery>

  <fullquery name="workflow::action::get_workflow_id_not_cached.select_workflow_id">
    <querytext>
        select workflow_id
        from workflow_actions
        where action_id = :action_id
    </querytext>
  </fullquery>

  <fullquery name="workflow::action::get_all_info_not_cached.action_callbacks">
    <querytext>
      select impl.impl_id,
             impl.impl_name,
             impl.impl_owner_name,
             ctr.contract_name,
             a.action_id
      from   workflow_action_callbacks ac,
             workflow_actions a,
             acs_sc_impls impl,
             acs_sc_bindings bind,
             acs_sc_contracts ctr
      where  ac.action_id = a.action_id
      and    a.workflow_id = :workflow_id
      and    impl.impl_id = ac.acs_sc_impl_id
      and    impl.impl_id = bind.impl_id
      and    bind.contract_id = ctr.contract_id
      order  by a.action_id, ac.sort_order
    </querytext>
  </fullquery>

  <fullquery name="workflow::action::get_all_info_not_cached.action_allowed_roles">
    <querytext>
      select r.short_name,
             r.role_id,
             aar.action_id
      from   workflow_roles r,
             workflow_action_allowed_roles aar
      where  r.workflow_id = :workflow_id
      and    r.role_id = aar.role_id
      order  by r.sort_order
    </querytext>
  </fullquery>

  <fullquery name="workflow::action::get_all_info_not_cached.action_enabled_in_states">
    <querytext>
        select s.state_id,
               s.short_name,
               waeis.action_id,
               waeis.assigned_p
        from   workflow_fsm_action_en_in_st waeis,
               workflow_actions a,
               workflow_fsm_states s
        where  waeis.action_id = a.action_id
        and    a.workflow_id = :workflow_id
        and    s.state_id = waeis.state_id
        order  by s.sort_order
    </querytext>
  </fullquery>

  <fullquery name="workflow::action::callback_insert.insert_callback">
    <querytext>
        insert into workflow_action_callbacks (action_id, acs_sc_impl_id, sort_order)
        values (:action_id, :acs_sc_impl_id, :sort_order)
    </querytext>
  </fullquery>

  <fullquery name="workflow::action::fsm::new.insert_fsm_action">
    <querytext>
        insert into workflow_fsm_actions
                (action_id, new_state)
            values
                (:action_id, :new_state_id)        
    </querytext>
  </fullquery>

  <fullquery name="workflow::action::fsm::edit.update_fsm_action">
    <querytext>
        update workflow_fsm_actions
        set    new_state = :new_state_id
        where  action_id = :action_id
    </querytext>
  </fullquery>

  <fullquery name="workflow::action::fsm::edit.delete_enabled_states">
    <querytext>
        delete from workflow_fsm_action_en_in_st
        where  action_id = :action_id
        and    assigned_p = :assigned_p
    </querytext>
  </fullquery>

  <fullquery name="workflow::action::fsm::edit.insert_enabled_state">
    <querytext>
        insert into workflow_fsm_action_en_in_st
                (action_id, state_id, assigned_p)
         values (:action_id, :enabled_state_id, :assigned_p)
    </querytext>
  </fullquery>

</queryset>

