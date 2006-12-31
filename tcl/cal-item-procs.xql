<?xml version="1.0"?>
<queryset>

<fullquery name="calendar::item::add_recurrence.update_event">
<querytext>
update acs_events 
set recurrence_id= :recurrence_id
where event_id= :cal_item_id
</querytext>
</fullquery>

<fullquery name="calendar::item::add_recurrence.insert_cal_items">
<querytext>
insert into cal_items 
(cal_item_id, on_which_calendar, item_type_id)
select
event_id, 
(select on_which_calendar 
as calendar_id from cal_items 
where cal_item_id = :cal_item_id),
(select item_type_id 
as item_type from cal_items 
where cal_item_id = :cal_item_id)
from acs_events where recurrence_id= :recurrence_id 
and event_id <> :cal_item_id
</querytext>
</fullquery>

<fullquery name="calendar::item::edit.select_recurrence_id">
<querytext>
select recurrence_id from acs_events where event_id= :cal_item_id
</querytext>
</fullquery>

<fullquery name="calendar::item::edit.update_activity">
    <querytext>
    update acs_activities 
    set    name = :name,
           description = :description
    where  activity_id
    in     (
           select activity_id
           from   acs_events
           where  event_id = :cal_item_id
           )
    </querytext>
</fullquery>

<fullquery name="calendar::item::edit.update_event">
    <querytext>
    update acs_events
    set    name = :name,
           description = :description
    where  event_id= :cal_item_id
    </querytext>
</fullquery>

<fullquery name="calendar::item::edit.get_interval_id">
    <querytext>
    select interval_id 
    from   timespans
    where  timespan_id
    in     (
           select timespan_id
           from   acs_events
           where  event_id = :cal_item_id
           )
    </querytext>
</fullquery>

<fullquery name="calendar::item::edit_recurrence.select_recurrence_id">
<querytext>
select recurrence_id from acs_events where event_id= :event_id
</querytext>
</fullquery>

<fullquery name="calendar::item::edit_recurrence.recurrence_activities_update">
    <querytext>
    update acs_activities 
    set    name = :name,
           description = :description
    where  activity_id
    in     (
           select activity_id
           from   acs_events
           where  recurrence_id = :recurrence_id
           )
    </querytext>
</fullquery>

<fullquery name="calendar::item::edit_recurrence.recurrence_events_update">
    <querytext>
    update acs_events set
    name= :name, description= :description
    where recurrence_id= :recurrence_id
    </querytext>
</fullquery>


<fullquery name="calendar::item::edit_recurrence.recurrence_items_update">
    <querytext>
            update cal_items
            set    [join $colspecs ", "]
            where  cal_item_id in (select event_id from acs_events where recurrence_id = :recurrence_id)
    </querytext>
</fullquery>
  
</queryset>
