<master>
<property name="title">#acs-workflow.Set_Deadline#</property>
<property name="context">@context;noquote@</property>

<form action="task-deadline-set-2" name="deadline">
@export_vars;noquote@
<table>
<tr><th align="right">#acs-workflow.Task#</th><td>@task.task_name@</td></tr>
<tr><th align="right">#acs-workflow.Deadline#</th>
<td>@date_widget@ <input type="submit" value="Set" /></td></tr>
</table>
</form>

</master>
