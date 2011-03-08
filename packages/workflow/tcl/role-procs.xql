<?xml version="1.0"?>
<queryset>

  <fullquery name="workflow::role::insert.do_insert">
    <querytext>
        insert into workflow_roles
                (role_id, workflow_id, short_name, pretty_name, sort_order)
             values
                (:role_id, :workflow_id, :short_name, :pretty_name, :sort_order)
    </querytext>
  </fullquery>

  <fullquery name="workflow::role::get_workflow_id_not_cached.select_workflow_id">
    <querytext>
        select workflow_id
        from workflow_roles
        where role_id = :role_id
    </querytext>
  </fullquery>

  <fullquery name="workflow::role::get_all_info_not_cached.role_info">
    <querytext>
        select role_id,
               workflow_id,
               short_name,
               pretty_name,
               sort_order
        from   workflow_roles
        where  workflow_id = :workflow_id
        order by sort_order
    </querytext>
  </fullquery>

  <fullquery name="workflow::role::get_all_info_not_cached.role_callbacks">
    <querytext>
        select c.role_id,
               impl.impl_id,
               impl.impl_owner_name,
               impl.impl_name,  
               ctr.contract_name,
               c.sort_order
        from   workflow_roles r,
               workflow_role_callbacks c,
               acs_sc_impls impl,
               acs_sc_bindings bind,
               acs_sc_contracts ctr
        where  r.workflow_id = :workflow_id
        and    c.role_id = r.role_id
        and    impl.impl_id = c.acs_sc_impl_id
        and    bind.impl_id = impl.impl_id
        and    ctr.contract_id = bind.contract_id
        order  by r.role_id, c.sort_order
    </querytext>
  </fullquery>

  <fullquery name="workflow::role::callback_insert.insert_callback">
    <querytext>
        insert into workflow_role_callbacks (role_id, acs_sc_impl_id, sort_order)
        values (:role_id, :acs_sc_impl_id, :sort_order)
    </querytext>
  </fullquery>

  <fullquery name="workflow::role::update_sort_order.select_sort_order_p">
    <querytext>
        select count(*)
        from   workflow_roles
        where  workflow_id = :workflow_id
        and    sort_order = :sort_order
    </querytext>
  </fullquery>

  <fullquery name="workflow::role::update_sort_order.update_sort_order">
    <querytext>
        update workflow_roles
        set    sort_order = sort_order + 1
        where  workflow_id = :workflow_id
        and    sort_order >= :sort_order
    </querytext>
  </fullquery>

</queryset>
