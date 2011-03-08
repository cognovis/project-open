<master>
<property name="title">Business Process Administration</property>
<property name="context">@context;noquote@</property>

<h3>Business Processes on This System</h3>

<if @workflows:rowcount@ eq 0>
    <em>no business processes installed</em>
</if>
<else>
    
    <table width="100%" cellspacing="2" cellpadding="2" border="0">
    <tr valign=middle class=rowtitle>
	<th width=150 class=rowtitle>Name</th>
	<th width=130 class=rowtitle>Cases</th>
	<th class=rowtitle>Description</th>
    </tr>
    
    <multiple name="workflows">
<if @workflows.row_even_p@>
	<tr class=roweven>
</if>
<else>
	<tr class=rowodd>
</else>
	    <td><a href="workflow?workflow_key=@workflows.workflow_key@">@workflows.pretty_name@</a><br>(@workflows.workflow_key@)</td>
	    <td align="center">
		<if @workflows.num_cases@ eq 0>No active cases</if>
		<if @workflows.num_cases@ eq 1><a href="workflow-summary?workflow_key=@workflows.workflow_key@">1 active case</a></if>
		<if @workflows.num_cases@ gt 1><a href="workflow-summary?workflow_key=@workflows.workflow_key@">@workflows.num_cases@ active cases</a></if>
    
		<if @workflows.num_unassigned_tasks@ gt 0>
		    <br />(<strong><a href="unassigned-tasks?workflow_key=@workflows.workflow_key@">@workflows.num_unassigned_tasks@ unassigned task<if @workflows.num_unassigned_tasks@ gt 1>s</if></a></strong>)
		</if>
	    </td>
	    <td>@workflows.description@</td>
	</tr>
    </multiple>
    
    </table>

</else>

<p>


<multiple name="actions">
    (<a href="@actions.url@">@actions.title@</a>)
</multiple>

</master>

