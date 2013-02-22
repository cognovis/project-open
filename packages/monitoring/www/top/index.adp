<master>
<property name="context">@context;noquote@</property>
<property name="title">@title;noquote@</property>
<SCRIPT Language="JavaScript" src="/resources/diagram/diagram/diagram.js"></SCRIPT>
<fieldset style="border: 2px solid rgb(204, 204, 204); margin: 10px; padding: 15px;">
<legend style="font-size: 14px; text-transform: uppercase; font-weight: bold;">#monitoring.system_options#</legend>
<a href="index2" class="button">#monitoring.show_register#</a>  <a href="run" class="button">#monitoring.show_top#</a>
</fieldset>
<fieldset style="border: 2px solid rgb(204, 204, 204); margin: 10px; padding: 15px;">
<legend style="font-size: 14px; text-transform: uppercase; font-weight: bold;">#monitoring.system_overview#</legend>
<table width="53%" border="0" cellpadding="0" cellspacing="0">
<tr>
<td height="30" valign="middle"><span style="margin-bottom:8px;">#monitoring.Memory_used#: @pct_memory_in_use@% :</span></td>
<td height="30" valign="middle"><img src="/resources/monitoring/@memory_color@" width="@pct_memory_in_use@" height="15"> <small> (@memory_in_use@MB)</small></td>
</tr>
<tr>
<td height="30" valign="middle"><span style="margin-bottom:8px;">#monitoring.Processor_used#: @cpu_total@%</span></td>
<td height="30" valign="middle"><img src="/resources/monitoring/@cpu_color@" width="@cpu_total@" height="15"> <small> (@cpu_total@%)</small></td>
</tr>
<tr>
<td height="30" valign="middle"><span style="margin-bottom:8px;">#monitoring.Swap_used#: @pct_swap_in_use@%</span></td>
<td height="30" valign="middle"><img src="/resources/monitoring/@swap_color@" width="@pct_swap_in_use@" height="15"><small> (@memory_swap_in_use@ MB)</small></td>
</tr>
</table>
</fieldset>


<fieldset style="border: 2px solid rgb(204, 204, 204); margin: 10px; padding: 15px;">
<legend style="font-size: 14px; text-transform: uppercase; font-weight: bold;">#monitoring.system_history#</legend>
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
<td><include src="memory_free"></td>
</tr>
<tr>
<td><include src="swap_in_use"></td>
</tr>
<tr>
<td><include src="cpu_in_use"></td>
</tr>
</table>
</fieldset>
</td>
</tr>
</table>
<fieldset style="border: 2px solid rgb(204, 204, 204); margin: 10px; padding: 15px;">
<legend style="font-size: 14px; text-transform: uppercase; font-weight: bold;">#monitoring.process_history#</legend>
<listtemplate name="procs"></listtemplate>
</fieldset>
