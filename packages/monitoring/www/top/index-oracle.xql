<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="mon_current_hour">      
    <querytext>

        select to_char(sysdate,'HH24') from dual

    </querytext>
</fullquery>

<partialquery name="hour_correction">      
    <querytext>

        + (24 - (:end_time - :current_hour)) / 24

    </querytext>
</partialquery>
 
<partialquery name="time_clause_2">      
    <querytext>

        and (timestamp + :n_days $hour_correction) > sysdate

    </querytext>
</partialquery>

<partialquery name="avg_proc_query">      
    <querytext>

  select pid, command, username,
         count(*) as count,
         $hour_sql as timestamp,
         round(avg(threads)) as threads,
         round(avg(to_number(rtrim(cpu_pct, '%'))), 2) as cpu_pct
    from ( select * from ad_monitoring_top $time_clause ) t, 
         ( select * from ad_monitoring_top_proc 
            where to_number(rtrim(cpu_pct, '%')) > :min_cpu_pct ) p
   where p.top_id = t.top_id
   group by pid, command, username, $hour_sql
   [ad_order_by_from_sort_spec $orderby $top_proc_avg_table_def] 

    </querytext>
</partialquery>

<partialquery name="load_and_memory_averages_sql">      
    <querytext>

        round(nvl(avg(load_avg_1), 0),  2) as load_average, 
        round(nvl(avg(memory_free),0), -2) as memory_free_average, 
        round(nvl(avg(memory_swap_free),  0), -2) as memory_swap_free_average,
        round(nvl(avg(memory_swap_in_use),0), -2) as memory_swap_in_use_average

    </querytext>
</partialquery>

<fullquery name="num_days_for_query">      
    <querytext>

    select round(max(timestamp) - min(timestamp) + 0.5) 
                  from ad_monitoring_top $time_clause

    </querytext>
</fullquery>


</queryset>
