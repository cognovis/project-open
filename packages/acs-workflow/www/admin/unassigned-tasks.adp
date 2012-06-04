<master>
<property name="title">#acs-workflow.Unassigned_Tasks#</property>
<property name="context">@context;noquote@</property>


<if @tasks:rowcount@ eq 0>
    <em>#acs-workflow.No_unassigned_tasks#</em>
</if>
<else>
    <table cellspacing="0" cellpadding="0" border="0">
    <tr><td bgcolor="#cccccc">
	
    <table width="100%" cellspacing="1" cellpadding="4" border="0">
    <tr valign="middle" bgcolor="#ffffe4">
	<th>#acs-workflow.Task#</th>
	<th>#acs-workflow.Case#</th>
	<th>#acs-workflow.Enabled#</th>
	<th>#acs-workflow.Deadline#</th>
    </tr>
    
    <multiple name="tasks">
	<tr bgcolor="#eeeeee">
	    <td><a href="../task?task_id=@tasks.task_id@">@tasks.transition_name@</a></td>
	    <td>@tasks.object_name@ (@tasks.object_type@)</td>
	    <td>
                <if @tasks.enabled_date_pretty@ not nil>@tasks.enabled_date_pretty@</if>
	        <else>&nbsp;</else>
            </td>
	    <td>
                <if @tasks.deadline_pretty@ not nil>@tasks.deadline_pretty@</if>
	        <else>&nbsp;</else>
            </td>
	</tr>
    </multiple>
    
    </table>
    
    </td></tr>
    </table>
</else>

</master>
