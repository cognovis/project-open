<?xml version="1.0"?>

<queryset>

<fullquery name="select_top">
      <querytext>
          select  top_id,
                  to_char(timestamp,'DD/MM/YY HH24:MI') as timestamp,
                  timehour,
                  load_avg_1,
                  load_avg_5,
                  load_avg_15,
                  memory_real,
                  memory_free,
                  memory_swap_free,
                  memory_swap_in_use,
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
         from     ad_monitoring_top
	 where top_id = :top_id       
      </querytext>
</fullquery> 


<fullquery name="select_top_proc">
      <querytext>
         select	proc_id,
  		top_id,
                pid,
  		username,
  		threads,
                priority,
                nice,
  		proc_size,
  		resident_memory,
  		state,
  		cpu_total_time,
  		cpu_pct,
  		command
         from   ad_monitoring_top_proc
	 where top_id = :top_id
      </querytext>
</fullquery>




</queryset>
