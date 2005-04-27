<master>
<property name="focus">workflow.workflow_name</property>
<property name="context">@context;noquote@</property>
<property name="title">Simple Process Wizard</property>

<include src="progress-bar" num_completed="0">

<p>

This wizard will help you quickly define a simple business
process. You can add a number of <b>tasks</b> to be executed in sequence, and
you can add <b>loops</b> that go back to a previous task. Finally, you can
set up the <b>assignment</b> rules.

<p>

If you want to create more advanced processes, you can either start
here and add flexibility later using the <b>Advanced Process Builder</b>, or
you can start with the Advanced Process Builder right away.

<p>

The first step is to give a <b>name</b> and an <b>optional description</b> to your
business process.

<p>

<form action="new-2" method=post name=workflow>

<table border=0>
<tr>
  <th align=right>Process Name:</th>
  <td><input maxlength=100 size=40 type=text name="workflow_name"
  value="@workflow_name@"></td>
</tr>
<tr>
  <th valign=top align=right>Description:</th>
  <td><textarea cols=60 rows=8 name=description>@description@</textarea></td>
</tr>
</table>

<center>
<input type=submit value="Next -&gt;">
</center>
</form>


</master>