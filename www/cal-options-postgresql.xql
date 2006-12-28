<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_readable_calendars">      
      <querytext>
      

    select  distinct(calendar_id) as calendar_id,
             calendar_name,
             ' '::varchar as checked_p
    from     calendars
    where    acs_permission__permission_p(calendar_id, :user_id, 'calendar_read') = 't'
    and      acs_permission__permission_p(calendar_id, :user_id, 'calendar_show') = 't'
    and      private_p = 'f'

    union 
    
    select  on_which_calendar as calendar_id,
            calendar_name,
            ' '::varchar as checked_p
    from    cal_items, calendars
    where   acs_permission__permission_p(cal_item_id, :user_id, 'cal_item_read') = 't'
    and     calendars.private_p = 'f'
    and     cal_items.on_which_calendar = calendars.calendar_id

      

      </querytext>
</fullquery>

 
</queryset>
