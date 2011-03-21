<master>
<property name="title">Add Task</property>
<property name="context">@context;noquote@</property>
<property name="focus">task.transition_name</property>

<form action="task-add-2" name="task">
@export_vars;noquote@

<table>
  <tr>
    <th align="right">Task name</th>
    <td><input type="text" size="80" name="transition_name" /></td>
  </tr>
  <tr>
    <th align=right>Trigger type</th>
    <td>
      <select name="trigger_type">
        <multiple name="trigger_types">
          <option value="@trigger_types.value@">@trigger_types.text@</option>
        </multiple>
      </select>
    </td>
  </tr>
  <tr>
    <th align="right">Role</th>
    <td>
      <select name="role_key">
        <multiple name="roles">
           <option value="@roles.role_key@">@roles.role_name@</option>
        </multiple>
      </select>
    </td>
  </tr>
  <tr>
    <th align="right">Time estimate</th>
    <td><input type="text" name="estimated_minutes" size="10" /> minutes</td>
  </tr>
  <tr>
    <th align="right">Instructions</th>
    <td><textarea name="instructions" rows="4" cols="45" wrap="soft"></textarea></td>
  </tr>
  <tr>
    <td colspan="2" align="center">
      <input type="submit" name="submit" value="Add" />
      &nbsp; &nbsp; &nbsp;
      <input type="submit" name="cancel" value="Cancel" />
    </td>
  </tr>
</table>

</form>

</master>

