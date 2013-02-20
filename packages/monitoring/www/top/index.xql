<?xml version="1.0"?>

<queryset>

<fullquery name="newest_top_id">
    <querytext>
      select max(top_id)     
      from   ad_monitoring_top
    </querytext>
</fullquery>


<fullquery name="max_cpu_pct">
    <querytext>
      select max(cpu_pct)
      from   ad_monitoring_top_proc
      where top_id = :top_id
    </querytext>
</fullquery>

<fullquery name="monitoring_top">
    <querytext>
      select memory_free,
             memory_real,
             memory_swap_free,
             memory_swap_in_use,
             cpu_idle
      from   ad_monitoring_top
      where  top_id = :top_id
    </querytext>
</fullquery>

<fullquery name="monitoring_top_proc_cpu">
    <querytext>
	select cpu_pct,
       		command,
       		pid,
       		username,
       		t.top_id,
       		to_char(t.timestamp,'DD/MM/YY HH24:MI') as timestamp
	from   ad_monitoring_top_proc p,
       	       ad_monitoring_top t
	where  t.top_id = p.top_id
	order by cpu_pct desc
	limit  7
    </querytext>
</fullquery>




</queryset>
