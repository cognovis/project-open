<?xml version="1.0"?>
<queryset>

<fullquery name="ad_monitor_top.top_proc_info_insert">      
<querytext>

    insert into ad_monitoring_top_proc (
        proc_id, 
        top_id, 
        pid, 
        command, 
        username, 
        threads, 
        priority, 
        nice, 
        proc_size, 
        resident_memory, 
        state, 
        cpu_total_time, 
        cpu_pct
    ) values (
        :proc_id, 
        :top_id, 
        :pid, 
        :command, 
        :username, 
        :threads, 
        :priority, 
        :nice, 
        :proc_size,  
        :resident_memory, 
        :state, 
        :cpu_total_time, 
        :cpu_pct
    ) 
      
</querytext>
</fullquery>

</queryset>
