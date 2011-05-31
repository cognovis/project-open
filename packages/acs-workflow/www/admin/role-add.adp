<master>
<property name="title">#acs-workflow.Add_Role#</property>
<property name="context">@context;noquote@</property>
<property name="focus">role.role_name</property>

<form action="role-add-2" name="role" method="post">
@export_vars;noquote@

<table>

<tr>
<th align="right">#acs-workflow.Role_name#</th>
<td><input type="text" size="40" name="role_name" /></td>
</tr>

<tr>
<td colspan="2" align="center">
<input type="submit" value="Add" />
</td>
</tr>

</table>

</form>

</master>

