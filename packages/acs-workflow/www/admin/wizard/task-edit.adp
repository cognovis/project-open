<master>
<property name="focus">task.task_name</property>
<property name="context">@context;noquote@</property>
<property name="title">Edit Task @task_name;noquote@</property>

Edit the task. The task name should be an imperative, such as "Write", "Review", "Assign", etc.

<form action="task-edit-2" method="post" name="task">
@export_vars;noquote@
<table>
<tr>
  <th align=right>Task name (e.g. "Write")</th>
  <td><input type=text name="task_name" size=40 maxlength=100 value="@task_name@"></td>
</tr>
<tr>
  <th align=right>Est. time to perform</th>
<td><input type=text name="task_time" size=8 value="@task_time@"> minutes</td>
</tr>
</table>

<center>
<input type=submit value="Update the task">
</center>
</form>

</master>