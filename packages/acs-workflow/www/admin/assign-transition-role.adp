<master>
<property name="title">Assign Transition to @role.role_name;noquote@</property>
<property name="context">@context;noquote@</property>

<form action="assign-transition-role-2" method="post">
@export_form_vars@
<table cellspacing="1" cellpadding="3" border="0">
  <tr>
    <th>Workflow</th>
    <td>@workflow.pretty_name@</td>
  </tr>
  <tr>
    <th>Role</th>
    <td>@role.role_name@</td>
  </tr>
  <tr>
    <th>Transition</th>
    <td><select name="transition_key">
        <multiple name="available_transitions">
         <option value="@available_transitions.transition_key@">@available_transitions.transition_name@</option>
        </multiple>
        </select>
    </td>
  </tr>
  <tr>
      <td colspan="2" align="center"><input type=submit value="Assign" /></td>
  </tr>  
</table>
</form>

</master>