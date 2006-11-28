<master>
<property name=title>@task.task_name;noquote@</property>
<property name="context">@context;noquote@</property>

<table width="100%" cellspacing="0" cellpadding="0" border="0">
<tr><td bgcolor="#cccccc">

	<table width="100%" cellspacing="1" cellpadding="2" border="0">
	<tr bgcolor="#9bbad6">
	    <th colspan="@panels:rowcount@"><big>Task: @task.task_name@</big></th>
	</tr>
<!--
	<tr valign="middle">
	    <multiple name="panels">
	        <th bgcolor="#ffffe4" width="@panel_width@%">@panels.header@</th>
	    </multiple>
	</tr>
-->
	<tr>


	    <multiple name="panels">
	        <td bgcolor="@panels.bgcolor@" valign="top">
		<!-- @panels.template_url@ -->
	    	<include src="@panels.template_url;noquote@" &="task" &="task_attributes_to_set" &="task_assigned_users" &="task_roles_to_assign" &="export_form_vars" &="return_url">
	        </td>
	    </multiple>


	</tr>
	</table>
	
</td></tr>
</table>

<p>

<if @extreme_p@ eq 1> 
	<table width="100%">
	<tr><td align="center" bgcolor="#dddddd">
	<small>
	Extreme actions: 
	<multiple name="extreme_actions">
	    (<a href="@extreme_actions.url@">@extreme_actions.title@</a>)
	</multiple>
	</small>
	</td></tr>
	</table>
</if>

<p>

<include src="journal" case_id="@case_id;noquote@">

</master>
