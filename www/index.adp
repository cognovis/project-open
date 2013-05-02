<master>
<property name="title">@title@</property>
<if @jsGraph@ eq 1> 
  <property name="header_stuff">
    <SCRIPT Language="JavaScript" src="/resources/xotcl-request-monitor/diagram/diagram.js"></SCRIPT>
  </property>
  <property name="head">
    <SCRIPT Language="JavaScript" src="/resources/xotcl-request-monitor/diagram/diagram.js"></SCRIPT>
  </property>
</if>


<table style="border: 0px solid blue; padding: 10px;">
  <tr><td><b>Active Users:</b></td><td>@active_user_string;noquote@</td><if @param_url@ ne "">
<td align="right"><a class="button" href="@param_url@">#acs-subsite.parameters#</a></td>
</if>
</tr>
  <tr><td><b>Current System Activity:</b></td><td>@current_system_activity@</td></tr>
  <tr><td><b>Current System Load:</b></td><td>@current_load@</td></tr>
  <tr><td><b>Current Avg Response Time/sec:</b></td><td>@current_response@</td></tr>
  <tr><td><b>Threads:</b></td><td>@running@ <a href='running'>Request(s)</a>
  currently running,  
  #connection threads @current_threads.current@ idle @current_threads.idle@,
  min @current_threads.min@ max @current_threads.max@
  <br>avg. #connection threads @thread_avgs.current@, avg. busy @thread_avgs.busy@</td></tr>
  <tr><td><b>Summaries:</b></td><td><a href='stat-details'>Aggregated URL</a> Statistics,
  <a href='last100'>Last 100</a> Requests,
  <a href='throttle-statistics'>Throttle</a> Statistics
</td><td><div style="font-size: 80%">
<a class='button' href="@toggle_graphics_url@">Toggle Graphics</a>
</div></td>
</tr>
</table>

<if @jsGraph@ eq 1> 
<table border='0'>
<tr><td colspan='2'><h3 style="margin-top:10px;">Page View Statistics</h3></td></tr>
@views_trend;noquote@

<tr><td colspan='2'><h3 style="margin-top:10px;">Active Users</h3></td></tr>
@users_trend;noquote@

<tr><td colspan='2'><h3 style="margin-top:10px;">Avg. Response Time in milliseconds</h3></td></tr>
@response_trend;noquote@

<tr><td colspan='2'><h3 style="margin-top:10px;">Throttle Statistics</h3></td></tr>
@throttle_stats;noquote@<br>

Detailed <a href='throttle-statistics'>Throttle statistics</a>
</table>
</if>
<else>
<h3 style='text-align: center;'>Page View Statistics</h3>
<div style="padding: 0px;">@views_trend;noquote@</div><p>

<h3 style='text-align: center;'>Active Users</h3>
<div style="padding: 0px;">@users_trend;noquote@</div><p>

<h3 style='text-align: center;'>Avg. Response Time in milliseconds</h3>
<div style="padding: 0px;">@response_trend;noquote@</div>

<div style="padding: 0px;">@throttle_stats;noquote@</div>
Detailed <a href='throttle-statistics'>Throttle statistics</a>
</else>

