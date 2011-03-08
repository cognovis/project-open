<?xml version="1.0"?>
<queryset>

  <fullquery name="workflow::state::fsm::update_sort_order.select_sort_order_p">
    <querytext>
        select count(*)
        from   workflow_fsm_states
        where  workflow_id = :workflow_id
        and    sort_order = :sort_order
    </querytext>
  </fullquery>

  <fullquery name="workflow::state::fsm::update_sort_order.update_sort_order">
    <querytext>
        update workflow_fsm_states
        set    sort_order = sort_order + 1
        where  workflow_id = :workflow_id
        and    sort_order >= :sort_order
    </querytext>
  </fullquery>

  <fullquery name="workflow::state::fsm::new.do_insert">
    <querytext>
        insert into workflow_fsm_states
                (state_id, workflow_id, sort_order, short_name, pretty_name, hide_fields)
         values (:state_id, :workflow_id, :sort_order, :short_name, :pretty_name, :hide_fields)
    </querytext>
  </fullquery>

  <fullquery name="workflow::state::fsm::get_id.select_id">
    <querytext>
        select state_id 
        from   workflow_fsm_states
        where  short_name = :short_name
        and    workflow_id = :workflow_id
    </querytext>
  </fullquery>

  <fullquery name="workflow::state::fsm::get_all_info_not_cached.select_states">
    <querytext>
      select s.workflow_id,
             s.state_id,
             s.sort_order,
             s.short_name,
             s.pretty_name,
             s.hide_fields,
             s.parent_action_id,
             (select short_name from workflow_actions where action_id = s.parent_action_id) as parent_action
      from   workflow_fsm_states s
      where  s.workflow_id = :workflow_id
      order by s.sort_order
    </querytext>
  </fullquery>

  <fullquery name="workflow::state::fsm::get_workflow_id_not_cached.select_workflow_id">
    <querytext>
        select workflow_id
        from   workflow_fsm_states
        where  state_id = :state_id
    </querytext>
  </fullquery>

  <fullquery name="workflow::state::fsm::edit.delete_enabled_actions">
    <querytext>
        delete from workflow_fsm_action_en_in_st
        where  state_id = :state_id
        and    assigned_p = :assigned_p
    </querytext>
  </fullquery>

  <fullquery name="workflow::state::fsm::edit.insert_enabled_action">
    <querytext>
        insert into workflow_fsm_action_en_in_st
                (action_id, state_id, assigned_p)
         values (:enabled_action_id, :state_id, :assigned_p)
    </querytext>
  </fullquery>

</queryset>
