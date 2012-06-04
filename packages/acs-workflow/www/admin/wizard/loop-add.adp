<master>
<property name="focus">#acs-workflow.lt_loopto_transition_key#</property>
<property name="context">@context;noquote@</property>
<property name="title">#acs-workflow.lt_Add_Loop_from_task_na#</property>

<form action="loop-add-2" name="loop">
@export_vars;noquote@

<blockquote>
<table cellspacing=0 cellpadding=0 border=0>
<tr><td bgcolor=#cccccc>

<table width="100%" cellspacing=1 cellpadding=4 border=0>
<tr>
<th align=right bgcolor=#ffffe4>#acs-workflow.Loop_from_task#</th>
<td bgcolor=#eeeeee>@task_name@</td>
</tr>

<tr>
<th align=right bgcolor=#ffffe4>#acs-workflow.Loop_to_task#</th>
<td bgcolor=#eeeeee>


<if @to_transitions:rowcount@ gt 1>
    <select name="to_transition_key" size="@to_transitions:rowcount@">
        <multiple name="to_transitions">
	    <option value="@to_transitions.transition_key@">@to_transitions.rownum@. @to_transitions.task_name@</option>
	</multiple>
    </select>
    <br><em>#acs-workflow.lt_Note_You_can_only_loo#</em>
</if>
<else>
    <multiple name="to_transitions">
        @to_transitions.task_name@ 
	<br><em>#acs-workflow.lt_this_is_the_only_task#</em>
        <input type="hidden" name="to_transition_key" value="@to_transitions.transition_key@">
    </multiple>
</else>

</td></tr>

<tr><th align=right bgcolor=#ffffe4>
#acs-workflow.Question_to_ask#
</th>
<td bgcolor=#eeeeee>
<input type=text name=question size=50><br>
<em>#acs-workflow.lt_make_it_a_yesno-quest#</em>
</td>
</tr>

<tr>
<th align=right bgcolor=#ffffe4>#acs-workflow.lt_Loop_back_if_answer_i#</th>
<td bgcolor=#eeeeee><select name=answer><option value="f">#acs-workflow.No_1#</option><option value="t">#acs-workflow.Yes#</option></select><br>
<em>#acs-workflow.lt_If_the_user_answers_w#</em>
</td>

</table>
</table>
</blockquote>

<center>
<input type=submit value="Add the loop">
</center>
</form>

</master>


