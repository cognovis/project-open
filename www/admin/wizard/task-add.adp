<master>
<property name="focus">task.task_name</property>
<property name="context">@context;noquote@</property>
<property name="title">Add Task to @workflow_name;noquote@</property>

Add a task to the process. The task name should be an imperative, such as "Write", "Review", "Assign", etc.

<form action="task-add-2" method="post" name="task">
<table>
<tr>
  <th align=right>Task name (e.g. "Write")</th>
  <td><input type=text name="task_name" size=40 maxlength=100></td>
</tr>
<tr>
  <th align=right>Est. time to perform</th>
  <td><input type=text name="task_time" size=8> minutes</td>
</tr>
</table>

<center>
<input type=submit value="Add the task">
</center>
</form>

</master>