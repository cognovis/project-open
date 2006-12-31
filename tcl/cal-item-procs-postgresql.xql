<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>
    <fullquery name="calendar::item::dates_valid_p.dates_valid_p_select">
      <querytext>
        select CASE WHEN :start_date::timestamptz <= :end_date::timestamptz
                    THEN 1
                    ELSE -1
               END 
      </querytext>
    </fullquery>

    <fullquery name="calendar::item::get.select_item_data">      
      <querytext>
      select
         i.cal_item_id,
         0 as n_attachments,
         to_char(start_date, 'YYYY-MM-DD HH24:MI:SS') as start_date_ansi,
         to_char(end_date, 'YYYY-MM-DD HH24:MI:SS') as end_date_ansi,
         coalesce(e.name, a.name) as name,
         coalesce(e.description, a.description) as description,
         recurrence_id,
         i.item_type_id,
         it.type as item_type,
         on_which_calendar as calendar_id,
         c.calendar_name,
         o.creation_user,
         c.package_id as calendar_package_id
       from
         acs_events e join timespans s
           on (e.timespan_id = s.timespan_id)
         join time_intervals t
           on (s.interval_id = t.interval_id)
         join acs_activities a
           on (e.activity_id = a.activity_id)
         join cal_items i
           on (e.event_id = i.cal_item_id)
         left join cal_item_types it
           on (it.item_type_id = i.item_type_id)
         left join calendars c
           on (c.calendar_id = i.on_which_calendar)
         left join acs_objects o
           on (o.object_id = i.cal_item_id)
       where
         e.event_id = :cal_item_id
      </querytext>
    </fullquery>

    <fullquery name="calendar::item::get.select_item_data_with_attachment">      
      <querytext>
       select
         i.cal_item_id,
         (select count(*) from attachments where object_id = cal_item_id) as n_attachments,
         to_char(start_date, 'YYYY-MM-DD HH24:MI:SS') as start_date_ansi,
         to_char(end_date, 'YYYY-MM-DD HH24:MI:SS') as end_date_ansi,
         coalesce(e.name, a.name) as name,
         coalesce(e.description, a.description) as description,
         recurrence_id,
         i.item_type_id,
         it.type as item_type,
         on_which_calendar as calendar_id,
         c.calendar_name,
         o.creation_user,
         c.package_id as calendar_package_id
       from
         acs_events e join timespans s
           on (e.timespan_id = s.timespan_id)
         join time_intervals t
           on (s.interval_id = t.interval_id)
         join acs_activities a
           on (e.activity_id = a.activity_id)
         join cal_items i
           on (e.event_id = i.cal_item_id)
         left join cal_item_types it
           on (it.item_type_id = i.item_type_id)
         left join calendars c
           on (c.calendar_id = i.on_which_calendar)
         left join acs_objects o
           on (o.object_id = i.cal_item_id)
       where
         e.event_id = :cal_item_id
     </querytext>
   </fullquery>

<fullquery name="calendar::item::add_recurrence.create_recurrence">
<querytext>
select recurrence__new(:interval_type,
    	:every_n,
    	:days_of_week,
    	:recur_until,
	NULL)
</querytext>
</fullquery>

<fullquery name="calendar::item::add_recurrence.insert_instances">
<querytext>
select acs_event__insert_instances(:cal_item_id, NULL);
</querytext>
</fullquery>

<fullquery name="calendar::item::new.insert_activity">      
      <querytext>
	select acs_activity__new (
					null,
					:name,
					:description,
					'f',
					null,
					'acs_activity', 
					now(),
					:creation_user,
					:creation_ip,
					null
	)

      </querytext>
</fullquery>


<fullquery name="calendar::item::new.insert_timespan">      
      <querytext>
	select timespan__new (    
					:start_date::timestamptz,
					:end_date::timestamptz
	) 

      </querytext>
</fullquery>

 
<fullquery name="calendar::item::new.cal_item_add">      
      <querytext>
	select cal_item__new (
					null,
					:calendar_id,
					:name,
					null,
                                        null,
                                        null,
					:timespan_id,
					:activity_id,
					null, 
					'cal_item',
					:calendar_id,
					now(),
					:creation_user,
					:creation_ip
	)

     </querytext>
</fullquery>

 
<fullquery name="calendar::item::delete.delete_cal_item">      
      <querytext>
	select cal_item__delete (
					:cal_item_id
	)

      </querytext>
</fullquery>

<fullquery name="calendar::item::edit.update_interval">      
      <querytext>
	select time_interval__edit (
					:interval_id,
					:start_date::timestamptz,
					:end_date::timestamptz
	)

      </querytext>
</fullquery>

 
<fullquery name="calendar::item::delete_recurrence.delete_cal_item_recurrence">      
      <querytext>
	select cal_item__delete_all (
					:recurrence_id
	)

      </querytext>
</fullquery>

<fullquery name="calendar::item::edit_recurrence.recurrence_timespan_update">
<querytext>
select
  acs_event__recurrence_timespan_edit (
    :event_id,
    :start_date,
    :end_date
  )
</querytext>
</fullquery>

</queryset>
