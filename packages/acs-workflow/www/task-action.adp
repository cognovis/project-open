
<!-- ----------------------------------------------------------------------
     "Approval Tasks" - An ugly but useful logic:

     Shows the action panels for "started" transitions already 
     while the transition is still in status "enabed". 
     This option saves users the click to "start task" for 
     approval type of tasks. These tasks are normally very short
     (just approve or not...), so the usual start-task logic
     doesn't make much sense.
---------------------------------------------------------------------- -->

<%

# "Approval Tasks" are identified by atleast one attribute
# to be set during the transition
set workflow_key $task(workflow_key)
set transition_key $task(transition_key)
set approval_attributes [db_list approval_attributes "
	select	attribute_id
	from	wf_transition_attribute_map tam
	where	tam.workflow_key = :workflow_key and
		tam.transition_key = :transition_key
"]
set approval_task_p 1
if {[llength $approval_attributes] == 0} { set approval_task_p 0 }


# Only use the approval_task logic if the current user
# is assigned to the task.
if {!$task(this_user_is_assigned_p)} { set approval_task_p 0 }

%>

<if @task.state@ eq enabled and @approval_task_p@ ne 1>
    <if @task.this_user_is_assigned_p@ eq 1>
        <form action="@task.action_url@" method="post">
	@export_form_vars;noquote@
	<table>
	<tr><th align="right">Action:</th>
	<td><input type="submit" name="action.start" value="Start task" /></td>
	</tr>
	</table>
	</form>

        <if @task_assigned_users:rowcount@ gt 1>
            <h4>Other assignees:</h4>
            <ul>
                <multiple name="task_assigned_users">
                    <if @task_assigned_users.user_id@ ne @user_id@>
                        <li><a href="/shared/community-member?user_id=@task_assigned_users.user_id@">@task_assigned_users.name@</a></li>
                    </if>
                </multiple>
	    </ul>
	</if>
        <else>
            You're the only person assigned to this task.
        </else>
    </if>
    <else>
        This task has not been started yet.

        <if @task_assigned_users:rowcount@ gt 0>
            <h4>Assignees:</h4>
            <ul>
                <multiple name="task_assigned_users">
                    <li><a href="/shared/community-member?user_id=@task_assigned_users.user_id@">@task_assigned_users.name@</a></li>
                </multiple>
	    </ul>
	</if>
    </else>

    <p>
    <ul class="admin_links">
    <if @task.this_user_is_assigned_p@ ne 1>
        <li><a href="@task.assign_yourself_url@">assign yourself</a></li>
    </if>
    <li><a href="@task.manage_assignments_url@">reassign</a></li>
    </ul>
    <if @task.deadline_pretty@ not nil>
        <p>
        <if @task.days_till_deadline@ lt 1>
            <font color="red"><strong>Deadline is @task.deadline_pretty@</strong></font>
	</if>
        <else>
            Deadline is @task.deadline_pretty@
        </else>
    </if>
</if>


<if @task.state@ eq started or @approval_task_p@>
    <if @task.this_user_is_assigned_p@ eq 1>
        <form action="task" method="post">
        @export_form_vars;noquote@
        <table>
        
            <multiple name="task_roles_to_assign">
                <tr>
                    <th align="right">Assign @task_roles_to_assign.role_name@</th>
                    <td>@task_roles_to_assign.assignment_widget;noquote@</td>
                </tr>
            </multiple>
    
            <multiple name="task_attributes_to_set">
                <tr>
                    <th align="right">@task_attributes_to_set.pretty_name@</th>
                    <td>@task_attributes_to_set.attribute_widget;noquote@</td>
                </tr>
             </multiple>
    
             <tr>
                 <th align="right">Comment<br></th>
                 <td><textarea name="msg" cols=20 rows=4></textarea></td>
             </tr>
    
             <tr>
                 <th align="right">Action</th>
                 <td>
                     <input type="submit" name="action.finish" value="Task done" />
                 </td>
             </tr>

        </table>
        </form>

        <table>
        <tr>
        <th>Started</th>
        <td>@task.started_date_pretty@
	&nbsp; &nbsp; </td>
        </tr>

        <if @task.hold_timeout_pretty@ not nil>
            <tr><th>Timeout</th><td>@task.hold_timeout_pretty@</td></tr>
        </if>

	<if @task.deadline_pretty@ not nil>
	    <tr><th>Deadline</th><td>
	    <if @task.days_till_deadline@ lt 1>
		<font color="red"><strong>Deadline is @task.deadline_pretty@</strong></font>
	    </if>
	    <else>
		Deadline is @task.deadline_pretty@
	    </else>
            </td></tr>
	</if>

        <tr>
	<td colspan="2"><ul class="admin_links"><li><a href="@task.cancel_url@">cancel task</a></li></ul></td>
        </tr>

        </table>
    </if>
    <else>
        <table>
            <tr><th>Held by</th><td><a href="/shared/community-member?user_id=@task.holding_user@">@task.holding_user_name@</a></td></tr>
            <tr><th>Since</th><td>@task.started_date_pretty@</td></tr>
            <tr><th>Timeout</th><td>@task.hold_timeout_pretty@</td></tr>
        </table>
    </else>
</if>

<if @task.state@ eq finished>
    <if @task.this_user_is_assigned_p@ eq 1>
        You finished this task on @task.finished_date_pretty@.
	<p>
	<a href="@return_url@">Go back</a>
    </if>
    <else>
        This task was completed by <a href="/shared/community-member?user_id=@task.holding_user@">@task.holding_user_name@</a>
        at @task.finished_date_pretty@
    </else>
</if>

<if @task.state@ eq canceled>
    <if @task.this_user_is_assigned_p@ eq 1>
        You canceled this task on @task.canceled_date_pretty@.
        <p>
        <a href="@return_url@">Go back</a>
    </if>
    <else>
        This task has been canceled by <a href="/shared/community-member?user_id=@task.holding_user@">@task.holding_user_name@</a>
        on @task.canceled_date_pretty@
    </else>
</if>
