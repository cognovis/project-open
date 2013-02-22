<?xml version="1.0"?>

<queryset>

<partialquery name="time_clause_1">      
    <querytext>

    where timehour >= :start_time and timehour < :end_time

    </querytext>
</partialquery>

<partialquery name="hour_sql">      
    <querytext>

    to_char(timestamp, 'MM/DD HH24') || ':00'

    </querytext>
</partialquery>

<partialquery name="day_sql">      
    <querytext>

    to_char(timestamp, 'Mon DD')

    </querytext>
</partialquery>
 
<partialquery name="avg_system_query">      
    <querytext>

  select $load_and_memory_averages_sql,
         count(*) as count,
         $day_sql as day
    from ad_monitoring_top
         $time_clause
   group by $day_sql
   [ad_order_by_from_sort_spec $orderbysystem $top_system_avg_table_def] 

    </querytext>
</partialquery>

</queryset>
