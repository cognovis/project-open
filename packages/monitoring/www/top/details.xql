<?xml version="1.0"?>

<queryset>

<partialquery name="time_clause_1">      
    <querytext>

    where timehour >= :start_time and timehour < :end_time

    </querytext>
</partialquery>

<partialquery name="system_query">      
    <querytext>

     select $load_and_memory_averages_sql,
            count(*) as count,
            $system_time_sql
       from ad_monitoring_top $time_clause  
        and $details_clause
      group by $system_group_by
      [ad_order_by_from_sort_spec $orderbysystem $top_system_table_def]

    </querytext>
</partialquery>

</queryset>
