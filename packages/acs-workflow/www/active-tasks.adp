<if @active_tasks:rowcount@ eq 0>
  <blockquote>
    <em>#acs-workflow.No_active_tasks#</em>
  </blockquote>
</if>
<else>
  <table cellspacing="0" cellpadding="0" border="0">
    <tr>
      <td bgcolor="#cccccc">
	<table width="100%" cellspacing="1" cellpadding="4" border="0">
	  <tr valign="middle" bgcolor="#ffffe4">
	    <th>#acs-workflow.Task_Name#</th>
	    <th>#acs-workflow.State#</th>
	    <th>#acs-workflow.Activated_Date#</th>
	    <th>#acs-workflow.Started_Date#</th>
	    <th>#acs-workflow.Deadline#</th>
            <th>#acs-workflow.Holder#</th>
            <th>#acs-workflow.Assignees#</th>
            <th>#acs-workflow.Action#</th>
	  </tr>
	  <multiple name="active_tasks">
	    <tr bgcolor="#eeeeee">
	      <td><a href="task?task_id=@active_tasks.task_id@&return_url=@return_url@">@active_tasks.transition_name@</a></td>
	      <td>@active_tasks.state@</td>
	      <td>@active_tasks.enabled_date_pretty@</td>
	      <td>
		<if @active_tasks.started_date_pretty@ not nil>@active_tasks.started_date_pretty@</if>
		<else><em>#acs-workflow.not_started#</em></else>
	      </td>
	      <td>
		<if @active_tasks.deadline_pretty@ not nil>@active_tasks.deadline_pretty@</if>
		<else>&nbsp;</else>
	      </td>
	      <td><a href="@holding_user_url@">@holding_user_name@</a></td>
              <td>
                <if @active_tasks.assignee_party_id@ not nil>
                  <group column="task_id">
		    <li>
		      <if @active_tasks.assignee_url@ not nil>
			<a href="@active_tasks.assignee_url@">@active_tasks.assignee_name@</a>
		      </if>
		      <else>
			@active_tasks.assignee_name@
		      </else>
<!--
		      <if @active_tasks.assignee_email@ not nil>
			(<a href="mailto:@active_tasks.assignee_email@">@active_tasks.assignee_email@</a>)
		      </if>
-->
		    </li>
                  </group>
                </if>
                <else>
                  <em>#acs-workflow.Unassigned#</em>
                </else>
              </td>
              <td>
                <if @active_tasks.reassign_url@ not nil>
                  (<a href="@active_tasks.reassign_url@">#acs-workflow.reassign#</a>)
                </if>
                <else>&nbsp;</else>
              </td>
	    </tr>
	  </multiple>
	</table>
      </td>
    </tr>
  </table>
</else>


