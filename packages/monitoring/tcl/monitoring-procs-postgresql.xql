<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="ad_monitor_top.top_misc_info_insert">      
    <querytext>

    insert into ad_monitoring_top (
        top_id, 
        timestamp, 
        timehour, 
        load_avg_1, 
        load_avg_5, 
        load_avg_15,
        memory_real, 
        memory_free, 
        memory_swap_in_use, 
        memory_swap_free,
	procs_total,
	procs_sleeping,
	procs_zombie,
	procs_stopped,
	procs_on_cpu,
        cpu_idle,
        cpu_user,
        cpu_kernel,
        cpu_iowait,
        cpu_swap
    ) values (
        :top_id, 
        current_timestamp, 
        to_char(current_timestamp, 'HH24')::integer, 
        :load_1, 
        :load_5, 
        :load_15,
        :memory_real, 
        :memory_free, 
        :memory_swap_in_use, 
        :memory_swap_free,
	:procs_total,
	:procs_sleeping,
	:procs_zombie,
	:procs_stopped,
	:procs_on_cpu,
        :cpu_idle,
        :cpu_user,
        :cpu_system,
        :cpu_nice,
        :cpu_si
    )

    </querytext>
</fullquery>


<fullquery name="ad_monitor_db_pgsql.db_misc_size_insert">      
    <querytext>

    insert into ad_monitoring_db (
        db_id, 
        timestamp, 
        timehour, 
        db_size,
        size_content_repository 
    ) values (
        :db_id, 
        current_timestamp, 
        to_char(current_timestamp, 'HH24')::integer, 
        :db_size,
        :size_content_repository
    )

    </querytext>
</fullquery>


<fullquery name="ad_monitor_db_pgsql.db_size_sql">
<querytext>

       select database_size(:database_name)

</querytext>
</fullquery>

<fullquery name="ad_monitor_db_pgsql.db_size_sql8">
<querytext>

       select * from pg_database_size(:database_name)

</querytext>
</fullquery>

 
</queryset>
