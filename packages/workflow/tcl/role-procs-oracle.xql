<?xml version="1.0"?>
<queryset>
  <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

  <fullquery name="workflow::role::callback_insert.select_sort_order">
    <querytext>
        select nvl(max(sort_order),0) + 1
        from   workflow_role_callbacks
        where  role_id = :role_id
    </querytext>
  </fullquery>

</queryset>
