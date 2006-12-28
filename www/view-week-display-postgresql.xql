<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>
	
<fullquery name="select_weekday_info">
<querytext>
        select   to_char(to_date(:start_date, 'YYYY-MM-DD'), 'D') 
        as       day_of_the_week,
        to_char(next_day(to_date(:start_date, 'YYYY-MM-DD')- '1 week'::interval, :first_us_weekday), 'YYYY-MM-DD')
        as       first_weekday_of_the_week,
        to_char(next_day(to_date(:start_date, 'YYYY-MM-DD'), :last_us_weekday), 'YYYY-MM-DD')
        as       last_weekday_of_the_week
        from     dual
</querytext>
</fullquery>

<fullquery name="select_week_items">
<querytext>
select   to_char(start_date, :ansi_date_format) as ansi_start_date,
         to_char(end_date, :ansi_date_format) as ansi_end_date,
         coalesce(e.name, a.name) as name,
         coalesce(e.status_summary, a.status_summary) as status_summary,
         e.event_id as item_id,
         (to_date(start_date,:ansi_date_format)  - to_date(:first_weekday_of_the_week_tz,
         :ansi_date_format)) as day_of_week,
         cals.calendar_id,
	 cals.calendar_name,
         cit.type as item_type
from     acs_activities a,
         acs_events e,
         timespans s,
         time_intervals t,
         calendars cals,
         cal_items ci left join
         cal_item_types cit on cit.item_type_id = ci.item_type_id
where    e.timespan_id = s.timespan_id
and      s.interval_id = t.interval_id
and      e.activity_id = a.activity_id
and      start_date between
         to_date(:first_weekday_of_the_week_tz, :ansi_date_format) and
         to_date(:last_weekday_of_the_week_tz, :ansi_date_format)
and      cals.calendar_id = ci.on_which_calendar
and      e.event_id = ci.cal_item_id
$calendars_clause
order by to_char(start_date, 'J'), to_char(start_date,'HH24:MI')
</querytext>
</fullquery>

<fullquery name="select_week_info">      
<querytext>
select   to_char(to_date(:start_date, 'YYYY-MM-DD'), 'D') 
as day_of_the_week,
cast(next_day(to_date(:start_date, 'YYYY-MM-DD') - cast('7 days' as interval), :first_us_weekday) as date)
as first_weekday_date,
to_char(next_day(to_date(:start_date, 'YYYY-MM-DD') - cast('7 days' as interval), :first_us_weekday),'J')
as first_weekday_julian,
cast(next_day(to_date(:start_date, 'YYYY-MM-DD') - cast('7 days' as interval), :first_us_weekday) + cast('6 days' as interval) as date)
as last_weekday_date,
to_char(next_day(to_date(:start_date, 'YYYY-MM-DD') - cast('7 days' as interval), :first_us_weekday) + cast('6 days' as interval),'J') 
as last_weekday_julian,
cast(:start_date::timestamptz - cast('7 days' as interval) as date) as last_week,
to_char(:start_date::timestamptz - cast('7 days' as interval), 'Month DD, YYYY') as last_week_pretty,
cast(:start_date::timestamptz + cast('7 days' as interval) as date) as next_week,
to_char(:start_date::timestamptz + cast('7 days' as interval), 'Month DD, YYYY') as next_week_pretty
from     dual
</querytext>
</fullquery>

</queryset>
