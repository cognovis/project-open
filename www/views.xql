<?xml version="1.0"?>
<queryset>

<partialquery name="openacs_calendar">      
  <querytext>
        and ((cals.package_id = :package_id and cals.private_p = 'f') 
             or (cals.private_p = 't' and cals.owner_id = :user_id))
  </querytext>
</partialquery>

<partialquery name="openacs_in_portal_calendar">      
  <querytext>
  and on_which_calendar in ([join $calendar_id_list ","]) and (cals.private_p='f' or (cals.private_p='t' and cals.owner_id= :user_id))
  </querytext>
</partialquery>

</queryset>
