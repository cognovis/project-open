<?xml version="1.0"?>
<queryset>

  <fullquery name="workflow::install::register_notification_types.enable_all_intervals">
    <querytext>
        insert into notification_types_intervals
        (type_id, interval_id)
        select :type_id, interval_id
        from   notification_intervals
    </querytext>
  </fullquery>

  <fullquery name="workflow::install::register_notification_types.enable_all_delivery_methods">
    <querytext>
        insert into notification_types_del_methods
        (type_id, delivery_method_id)
        select :type_id, delivery_method_id
        from   notification_delivery_methods
    </querytext>
  </fullquery>

</queryset>


