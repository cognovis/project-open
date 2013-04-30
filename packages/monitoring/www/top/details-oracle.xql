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
 
<partialquery name="proc_query">      
    <querytext>

  select pid, command, username, 
         $proc_time_sql,
         count(*) as count,
         round(avg(threads),0) as threads, 
         round(avg(to_number(rtrim(cpu_pct, '%'))),2) as cpu_pct
    from (select * from ad_monitoring_top_proc
           where to_number(rtrim(cpu_pct, '%')) > :min_cpu_pct) p, 
         (select * from ad_monitoring_top where $time_clause) t
    where p.top_id = t.top_id
      and $details_clause
   group by pid, command, username, $proc_group_by
   [ad_order_by_from_sort_spec $orderby $top_proc_table_def]

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

<fullquery name="mon_top_entries">      
    <querytext>

     select count(*) 
        from (select * from ad_monitoring_top  where $time_clause) t, 
             (select * from ad_monitoring_top_proc 
               where to_number(rtrim(cpu_pct, '%')) > :min_cpu_pct) p
      where t.top_id = p.top_id
        and $details_clause      

    </querytext>
</fullquery>

</queryset>
