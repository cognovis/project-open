<master>
<property name="title">Task @transition_name;noquote@</property>
<property name="context">@context;noquote@</property>
<property name="focus">@focus;noquote@</property>

<form action="task-edit-2" name="task" method="post">
@export_vars;noquote@

<table>
  <tr>
    <th align="right">Task name</th>
    <td>
      <input type="text" size="80" name="transition_name" value="@transition_name@" />
    </td>
  </tr>
  <tr>
    <th align="right">Trigger type</th>
    <td>
      <select name="trigger_type">
        <multiple name="trigger_types">
          <option value="@trigger_types.value@" @trigger_types.selected_string@>@trigger_types.text@</option>  
        </multiple>
      </select>
    </td>
  </tr>
  <tr>
    <th align="right">Role</th>
    <td>
      <if @new_role_p@ eq 1>
        <font color="red"><em>Please type a name for the new role</em></font><br />
        <input type="text" name="role_name" size="50" />
      </if>
      <else>
	<select name="role_key">
	  <multiple name="roles">
	     <option value="@roles.role_key@" @roles.selected_string@>@roles.role_name@</option>
	  </multiple>
	</select>
      </else>
    </td>
  </tr>
  <tr>
    <th align="right">Time estimate</th>
    <td><input type="text" name="estimated_minutes" value="@estimated_minutes@" /> minutes</td>
  </tr> 
  <tr>
    <th align="right">Instructions</th>
    <td><textarea name="instructions" rows="4" cols="45" wrap="soft">@instructions@</textarea></td>
  </tr>
  <tr>
    <td colspan=2 align=center>
      <input type="submit" name="submit" value="Update" />
      &nbsp; &nbsp; &nbsp;
      <input type="submit" name="cancel" value="Cancel" />
    </td>
  </tr>
</table>

</form>

</master>
