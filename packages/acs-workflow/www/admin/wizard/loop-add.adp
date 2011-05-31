<master>
<property name="focus"><#lt_loopto_transition_key loop.to_transition_key#></property>
<property name="context">@context;noquote@</property>
<property name="title"><#lt_Add_Loop_from_task_na Add Loop from @task_name;noquote@#></property>

<form action="loop-add-2" name="loop">
@export_vars;noquote@

<blockquote>
<table cellspacing=0 cellpadding=0 border=0>
<tr><td bgcolor=#cccccc>

<table width="100%" cellspacing=1 cellpadding=4 border=0>
<tr>
<th align=right bgcolor=#ffffe4><#Loop_from_task Loop from task#></th>
<td bgcolor=#eeeeee>@task_name@</td>
</tr>

<tr>
<th align=right bgcolor=#ffffe4><#Loop_to_task Loop to task#></th>
<td bgcolor=#eeeeee>


<if @to_transitions:rowcount@ gt 1>
    <select name="to_transition_key" size="@to_transitions:rowcount@">
        <multiple name="to_transitions">
	    <option value="@to_transitions.transition_key@">@to_transitions.rownum@. @to_transitions.task_name@</option>
	</multiple>
    </select>
    <br><em><#lt_Note_You_can_only_loo (Note. You can only loop backwards in the process)#></em>
</if>
<else>
    <multiple name="to_transitions">
        @to_transitions.task_name@ 
	<br><em><#lt_this_is_the_only_task (this is the only task you can possibly loop to from here)#></em>
        <input type="hidden" name="to_transition_key" value="@to_transitions.transition_key@">
    </multiple>
</else>

</td></tr>

<tr><th align=right bgcolor=#ffffe4>
<#Question_to_ask Question to ask#>
</th>
<td bgcolor=#eeeeee>
<input type=text name=question size=50><br>
<em><#lt_make_it_a_yesno-quest (make it a yes/no-question, e.g. "Approved")#></em>
</td>
</tr>

<tr>
<th align=right bgcolor=#ffffe4><#lt_Loop_back_if_answer_i Loop back if answer is#></th>
<td bgcolor=#eeeeee><select name=answer><option value="f"><#No No#></option><option value="t"><#Yes Yes#></option></select><br>
<em><#lt_If_the_user_answers_w (If the user answers what you specify here, we'll loop back. If he choses the other answer, we'll continue with the next task.)#></em>
</td>

</table>
</table>
</blockquote>

<center>
<input type=submit value="Add the loop">
</center>
</form>

</master>


