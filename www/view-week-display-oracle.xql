<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="select_weekday_info">
<querytext>
        select   to_char(to_date(:start_date, 'YYYY-MM-DD'), 'D') 
        as       day_of_the_week,
        to_char(next_day(to_date(:start_date, 'YYYY-MM-DD')-7, :first_us_weekday)) 
        as       first_weekday_of_the_week,
        to_char(next_day(to_date(:start_date, 'YYYY-MM-DD')-7, :first_us_weekday) + 6)
        as       last_weekday_of_the_week
        from dual
</querytext>
</fullquery>
	
<partialquery name="dow">
<querytext>
   , to_char(to_date(:start_date, 'YYYY-MM-DD'), 'D') as day_of_the_week
</querytext>
</partialquery>

<fullquery name="select_week_info">
<querytext>
select  to_char(to_date(:start_date, 'YYYY-MM-DD'), 'D') as day_of_the_week, 
next_day(to_date(:start_date, 'YYYY-MM-DD') - 7, :first_us_weekday) as first_weekday_date,
to_char(next_day(to_date(:start_date, 'YYYY-MM-DD') - 7, :first_us_weekday),'J') as first_weekday_julian,
next_day(to_date(:start_date, 'YYYY-MM-DD') - 7, :first_us_weekday) + 6 as last_weekday_date,
to_char(next_day(to_date(:start_date, 'YYYY-MM-DD') - 7, :first_us_weekday) + 6,'J') as last_weekday_julian,
to_char(to_date(:start_date) - 7, 'YYYY-MM-DD') as last_week,
to_char(to_date(:start_date) - 7, 'Month DD, YYYY') as last_week_pretty,
to_char(to_date(:start_date) + 7, 'YYYY-MM-DD') as next_week,
to_char(to_date(:start_date) + 7, 'Month DD, YYYY') as next_week_pretty
from dual
</querytext>
</fullquery>

</queryset>
