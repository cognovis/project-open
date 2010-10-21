<?xml version="1.0"?>
<queryset>

<fullquery name="calendar::apm::package_after_upgrade.update_context">
<querytext>
  update acs_objects
  set security_inherit_p = 'f'
  where object_id in (select calendar_id from calendars  
                      where calendar_name = 'Personal')
</querytext>
</fullquery>

<fullquery name="calendar::apm::package_after_upgrade.remove_personal_notifications">
<querytext>
  delete from notification_requests
  where request_id in (select request_id
                       from notification_requests, calendars 
                       where calendar_name = 'Personal' and package_id = object_id
                         and type_id = (select type_id
                                        from notification_types 
                                        where short_name = 'calendar_notif'))
</querytext>
</fullquery>

</queryset>
