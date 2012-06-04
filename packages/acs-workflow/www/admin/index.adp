<master>
<property name="title">#acs-workflow.lt_Business_Process_Admi#</property>
<property name="context">@context;noquote@</property>
<property name="left_navbar">@left_navbar_html;noquote@</property>

<h3>#acs-workflow.lt_Business_Processes_on#</h3>

<if @workflows:rowcount@ eq 0>
    <em>#acs-workflow.lt_no_business_processes#</em>
</if>
<else>
    
    <table width="100%" cellspacing="2" cellpadding="2" border="0">
    <tr valign=middle class=rowtitle>
	<th width=150 class=rowtitle>#acs-workflow.Name#</th>
	<th width=130 class=rowtitle>#acs-workflow.Cases#</th>
	<th class=rowtitle>#acs-workflow.Description#</th>
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
		<if @workflows.num_cases@ eq 0>#acs-workflow.No_active_cases#</if>
		<if @workflows.num_cases@ eq 1><a href="workflow-summary?workflow_key=@workflows.workflow_key@">#acs-workflow.1_active_case#</a></if>
		<if @workflows.num_cases@ gt 1><a href="workflow-summary?workflow_key=@workflows.workflow_key@">#acs-workflow.lt_workflowsnum_cases_ac#</a></if>
    
		<if @workflows.num_unassigned_tasks@ gt 0>
		    <br />(<strong><a href="unassigned-tasks?workflow_key=@workflows.workflow_key@">#acs-workflow.lt_workflowsnum_unassign#<if @workflows.num_unassigned_tasks@ gt 1>s</if></a></strong>)
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


