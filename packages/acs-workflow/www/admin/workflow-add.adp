<master>
<property name="title">#acs-workflow.New_Advanced_Process#</property>
<property name="context">@context;noquote@</property>
<property name="focus">workflow.workflow_name</property>

#acs-workflow.lt_The_first_step_in_def#

<p>


<form action="workflow-add-2" name="workflow">

<table>

<tr>
<th align="right">#acs-workflow.Process_Name#</th>
<td><input type="text" size="80" name="workflow_name" /></td>
</tr>

<tr>
<th align="right">#acs-workflow.Description#
<br><small>#acs-workflow.optional#</small></th>
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


