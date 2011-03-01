<master>
<property name="title">New Advanced Process</property>
<property name="context">@context;noquote@</property>
<property name="focus">workflow.workflow_name</property>

The first step in defining a new process is to give it a name and an
optional description.  Examples of good names are "marketing
interview", "article publication" or "expenses approval".

<p>


<form action="workflow-add-2" name="workflow">

<table>

<tr>
<th align="right">Process Name</th>
<td><input type="text" size="80" name="workflow_name" /></td>
</tr>

<tr>
<th align="right">Description
<br><small>(optional)</small></th>
<td><textarea name="description" cols="60" rows="8"></textarea>
</td>
</tr>

<tr>
<td colspan="2" align="center">
<input type="submit" value="Add" />
</td>
</tr>

</table>

</form>

</master>

