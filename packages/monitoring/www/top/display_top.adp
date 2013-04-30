<master>
<property name="context">@context;noquote@</property>
<property name="title">@title;noquote@</property>
<a href="index2" class="button"> Voltar </a>
<table border=0>
<tr>
 <th align=left>
top -  @timestamp@ up, load average: @load_avg_1@, @load_avg_5@, @load_avg_15@ 
 </th>
</tr> 
<tr>
 <th align=left>
Tasks:  @procs_total@ total, @procs_on_cpu@ running, @procs_sleeping@ sleeping, @procs_stopped@ stopped, @procs_zombie@ zombie <br>
 </th>
</tr>
<tr>
 <th align=left>
Cpu(s): @cpu_user@%us,  @cpu_kernel@%sy,  @cpu_idle@%id, @cpu_iowait@%wa, @cpu_swap@%si<br>
 </th>
</tr>
<tr>
 <th align=left>
   Mem:    @memory_real@k total, @memory_used@k used, @memory_free@k free<br>
 </th>
</tr>
<tr>
 <th align=left>
   Swap:   @memory_swap_real@k total, @memory_swap_in_use@k used, @memory_swap_free@k free<br>
 </th>
</tr>
</table>

<br>
<br>
<table border=0>
  <tr>
   <th>
	 PID
   </th>
   <th>
         USER
   </th>
   <th>
	 NI
   </th>
   <th>
         VIRT
   </th>
   <th>
         RES
   </th>
   <th>
         SHR
   </th>
   <th>
         S
   </th>
   <th>
         %CPU
   </th>
   <th>
         %MEM
   </th>
   <th>
         TIME+
   </th>
   <th>
         COMMAND 
   </th>
</tr>

<multiple name="top_procs">

  <tr>
    <th>
       @top_procs.pid@
    </th>
    <th>
       @top_procs.username@
    </th>
    <th>
        @top_procs.threads@
    </th>
    <th>
       @top_procs.priority@
    </th>
    <th>
        @top_procs.nice@ 
    </th>
    <th>
        @top_procs.proc_size@
    </th>
    <th>
       @top_procs.resident_memory@
    </th>
    <th>
       @top_procs.state@
    </th>
    <th>
       @top_procs.cpu_total_time@ 
   </th>
   <th>
      @top_procs.cpu_pct@     
   </th>
   <th>
     <a href="one-pid?pid=@top_procs.pid@&command=@top_procs.command@&top_id=@top_id@"> @top_procs.command@ </a>
   </th>
</tr>

</multiple>
</table>

