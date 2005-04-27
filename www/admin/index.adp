<master>
<property name="title">Business Process Administration</property>
<property name="context">@context;noquote@</property>

<h3>Business Processes on This System</h3>

<if @workflows:rowcount@ eq 0>
    <em>no business processes installed</em>
</if>
<else>
    <table cellspacing="0" cellpadding="0" border="0">
    <tr><td bgcolor="#cccccc">
    
    <table width="100%" cellspacing="1" cellpadding="4" border="0">
    <tr valign=middle bgcolor="#ffffe4">
	<th>Name</th>
	<th>Description</th>
	<th>Cases</th>
    </tr>
    
    <multiple name="workflows">
	<tr bgcolor="#eeeeee">
	    <td><a href="workflow?workflow_key=@workflows.workflow_key@">@workflows.pretty_name@</a></td>
	    <td>@workflows.description@</td>
	    <td align="center">
		<if @workflows.num_cases@ eq 0>No active cases</if>
		<if @workflows.num_cases@ eq 1><a href="workflow-summary?workflow_key=@workflows.workflow_key@">1 active case</a></if>
		<if @workflows.num_cases@ gt 1><a href="workflow-summary?workflow_key=@workflows.workflow_key@">@workflows.num_cases@ active cases</a></if>
    
		<if @workflows.num_unassigned_tasks@ gt 0>
		    <br />(<strong><a href="unassigned-tasks?workflow_key=@workflows.workflow_key@">@workflows.num_unassigned_tasks@ unassigned task<if @workflows.num_unassigned_tasks@ gt 1>s</if></a></strong>)
		</if>
	    </td>
	</tr>
    </multiple>
    
    </table>
    </td></tr>
    </table>
</else>

<p>


<multiple name="actions">
    (<a href="@actions.url@">@actions.title@</a>)
</multiple>

</master>

