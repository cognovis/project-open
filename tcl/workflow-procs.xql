<?xml version="1.0"?>
<queryset>

  <fullquery name="workflow::get_id_not_cached.select_workflow_id_by_object_id">
    <querytext>
      select workflow_id
      from   workflows
      where  object_id = :object_id
      and    short_name = :short_name                        
    </querytext>
  </fullquery>

  <fullquery name="workflow::exists_p.do_select">
    <querytext>
        select count(*) from workflows where workflow_id = :workflow_id
    </querytext>
  </fullquery>

  <fullquery name="workflow::get_not_cached.workflow_callbacks">
    <querytext>
      select impl.impl_id,
             impl.impl_name,
             impl.impl_owner_name,
             ctr.contract_name,
             wc.sort_order
      from   workflow_callbacks wc,
             acs_sc_impls impl,
             acs_sc_bindings bind,
             acs_sc_contracts ctr
      where  wc.workflow_id = :workflow_id
      and    impl.impl_id = wc.acs_sc_impl_id
      and    impl.impl_id = bind.impl_id
      and    bind.contract_id = ctr.contract_id
      order  by wc.sort_order
    </querytext>
  </fullquery>

  <fullquery name="workflow::get_id_not_cached.select_workflow_id_by_package_key">
    <querytext>
      select workflow_id
      from   workflows
      where  package_key = :package_key
      and    short_name = :short_name                        
      and    object_id is null
    </querytext>
  </fullquery>

  <fullquery name="workflow::default_sort_order.max_sort_order">
    <querytext>
        select max(sort_order)
        from   $table_name
        where  workflow_id = :workflow_id
    </querytext>
  </fullquery>
 
  <fullquery name="workflow::callback_insert.insert_callback">
    <querytext>
        insert into workflow_callbacks (workflow_id, acs_sc_impl_id, sort_order)
        values (:workflow_id, :acs_sc_impl_id, :sort_order)
    </querytext>
  </fullquery>

</queryset>
