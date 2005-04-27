<master>
<property name="title">Edit Process Name</property>
<property name="context">@context;noquote@</property>
<property name="focus">workflow.workflow_name</property>

<form action="name-edit-2" name="workflow">
@export_vars;noquote@

<table>

<tr>
<th align="right">Process Name</th>
<td><input type="text" size="80" name="workflow_name" value="@workflow_name@" /></td>
</tr>

<tr>
<th align="right">Description</th>
<td><textarea name="description" cols="60" rows="8">@description@</textarea>
</td>
</tr>

<tr>
<td colspan="2" align="center">
<input type="submit" value="Update" />
</td>
</tr>

</table>

</form>

</master>