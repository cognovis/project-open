<master>
<property name="focus">#acs-workflow.lt_workflowworkflow_name#</property>
<property name="context">@context;noquote@</property>
<property name="title">#acs-workflow.lt_Simple_Process_Wizard_1#</property>

<include src="progress-bar" num_completed="0">

<p>

#acs-workflow.lt_This_wizard_will_help# <b>#acs-workflow.tasks#</b> #acs-workflow.lt_to_be_executed_in_seq# <b>#acs-workflow.loops#</b> #acs-workflow.lt_that_go_back_to_a_pre# <b>#acs-workflow.assignment#</b> #acs-workflow.rules#

<p>

#acs-workflow.lt_If_you_want_to_create# <b>#acs-workflow.lt_Advanced_Process_Buil#</b>#acs-workflow.lt__oryou_can_start_with#

<p>

#acs-workflow.lt_The_first_step_is_to_# <b>#acs-workflow.name#</b> #acs-workflow.and_an# <b>#acs-workflow.optional_description#</b> #acs-workflow.lt_to_yourbusiness_proce#

<p>

<form action="new-2" method=post name=workflow>

<table border=0>
<tr>
  <th align=right>#acs-workflow.Process_Name_1#</th>
  <td><input maxlength=100 size=40 type=text name="workflow_name"
  value="@workflow_name@"></td>
</tr>
<tr>
  <th valign=top align=right>#acs-workflow.Description_1#</th>
  <td><textarea cols=60 rows=8 name=description>@description@</textarea></td>
</tr>
</table>

<center>
<input type=submit value="Next -&gt;">
</center>
</form>


</master>
