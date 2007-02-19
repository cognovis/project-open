<?xml version="1.0"?>

<queryset>
  <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

  <fullquery name="get_impl_name_and_count">
    <querytext>
    select acs_sc_impl.get_name(impl_id) as impl_name
    from acs_sc_impls
    where impl_id = :impl_id
    </querytext>
  </fullquery>

</queryset>
