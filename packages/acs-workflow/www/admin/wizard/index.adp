<master>
<property name="focus"><#lt_workflowworkflow_name workflow.workflow_name#></property>
<property name="context">@context;noquote@</property>
<property name="title"><#lt_Simple_Process_Wizard Simple Process Wizard#></property>

<include src="progress-bar" num_completed="0">

<p>

<#lt_This_wizard_will_help This wizard will help you quickly define a simple business
process. You can add a number of#> <b><#tasks tasks#></b> <#lt_to_be_executed_in_seq to be executed in sequence, and
you can add#> <b><#loops loops#></b> <#lt_that_go_back_to_a_pre that go back to a previous task. Finally, you can
set up the#> <b><#assignment assignment#></b> <#rules rules.#>

<p>

<#lt_If_you_want_to_create If you want to create more advanced processes, you can either start
here and add flexibility later using the#> <b><#lt_Advanced_Process_Buil Advanced Process Builder#></b><#lt__oryou_can_start_with , or
you can start with the Advanced Process Builder right away.#>

<p>

<#lt_The_first_step_is_to_ The first step is to give a#> <b><#name name#></b> <#and_an and an#> <b><#optional_description optional description#></b> <#lt_to_yourbusiness_proce to your
business process.#>

<p>

<form action="new-2" method=post name=workflow>

<table border=0>
<tr>
  <th align=right><#Process_Name Process Name:#></th>
  <td><input maxlength=100 size=40 type=text name="workflow_name"
  value="@workflow_name@"></td>
</tr>
<tr>
  <th valign=top align=right><#Description Description:#></th>
  <td><textarea cols=60 rows=8 name=description>@description@</textarea></td>
</tr>
</table>

<center>
<input type=submit value="Next -&gt;">
</center>
</form>


</master>
