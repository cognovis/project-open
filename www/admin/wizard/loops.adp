<master>
<property name="title">#acs-workflow.lt_Simple_Process_Wizard_2#</property>
<property name="context">@context;noquote@</property>

<include src="progress-bar" num_completed="2">

<p>

<if @tasks:rowcount@ eq 0>
    #acs-workflow.lt_You_havent_defined_an# <a href="tasks">#acs-workflow.lt_go_back_and_define_so#</a> #acs-workflow.now#
</if>

<if @tasks:rowcount eq 1>
    #acs-workflow.You_only_have# <b>#acs-workflow.one_task_defined#</b>#acs-workflow.lt__Thats_barely____enou# <em>#acs-workflow.process#</em>#acs-workflow.lt__so_you_probably_want# <a
    href="tasks">#acs-workflow.lt_go_back_and_define_mo#</a>. 

    <p>

    #acs-workflow.lt_If_you_insist_that_yo# <b>#acs-workflow.lt_add_a_loop_from_loop_#</b>#acs-workflow.lt__The____way_it_works_#

</if>

<if @tasks:rowcount@ ge 2>
    #acs-workflow.lt_A_loop_always_goes_ba# <b>#acs-workflow.prior_task#</b> #acs-workflow.lt_in_the_process_eg_fro# 
    
    <p>
    
    #acs-workflow.We_will_ask_him_a# <b>#acs-workflow.yesno_question#</b>#acs-workflow.lt__such_as____Approved_#
    
    <p>
    
    #acs-workflow.lt_In_the_list_below_hit# <b>#acs-workflow.lt_the_task_you_want_to_#</b>#acs-workflow._ie_the# <b>#acs-workflow.last#</b> #acs-workflow.task_in_the_loop# 
</if>

<blockquote>
<table cellspacing=0 cellpadding=0 border=0>
<tr><td bgcolor=#cccccc>

<table width="100%" cellspacing=1 cellpadding=4 border=0>
<tr bgcolor=#ffffe4>
<th>#acs-workflow.Order#</th>
<th>#acs-workflow.Task#</th>
<th>#acs-workflow.Loop#</th>
<th>#acs-workflow.Action#</th>
</tr>

<multiple name="tasks">
    <tr valign=middle bgcolor=#eeeeee>
    <td align=right>@tasks.rownum@.</td>
    <td align=left>@tasks.task_name@</td>
    <td align=left>

    <if @tasks.loop_to_task_name@ not nil>
	#acs-workflow.lt_Go_to_tasksloop_to_ta#
	<if @tasks.loop_answer@ eq "f">#acs-workflow.not#</if>
	@tasks.loop_question@
    </if>
    <else>&nbsp;</else>

    </td>
    <td align=center>
    
    <if @tasks.loop_to_task_name@ nil>
	(<a href="loop-add?from_transition_key=@tasks.transition_key@">#acs-workflow.add_loop#</a>)
    </if>
    <else>
 	(<a href="loop-delete?from_transition_key=@tasks.transition_key@">#acs-workflow.remove_loop#</a>)
    </else>

    </td>
    </tr>
</multiple>

</table>
</table>
</blockquote>
<p>

<p>&nbsp;<p>

<form action="assignments" method=post>
<center>
<input type=submit value="Next -&gt;">
<br>#acs-workflow.Hit_Next_when_youre# <b>#acs-workflow.done_adding_loops#</b>.
</center>
</form>

</master>

