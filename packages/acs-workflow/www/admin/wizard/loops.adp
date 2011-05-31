<master>
<property name="title"><#lt_Simple_Process_Wizard Simple Process Wizard Step 3: Loops for @workflow_name;noquote@#></property>
<property name="context">@context;noquote@</property>

<include src="progress-bar" num_completed="2">

<p>

<if @tasks:rowcount@ eq 0>
    <#lt_You_havent_defined_an You haven't defined any tasks yet. 
    Please#> <a href="tasks"><#lt_go_back_and_define_so go back and define some tasks#></a> <#now now.#>
</if>

<if @tasks:rowcount eq 1>
    <#You_only_have You only have#> <b><#one_task_defined one task defined#></b><#lt__Thats_barely____enou . That's barely
    enough to call a#> <em><#process process#></em><#lt__so_you_probably_want , so you probably want to#> <a
    href="tasks"><#lt_go_back_and_define_mo go back and define more tasks#></a>. 

    <p>

    <#lt_If_you_insist_that_yo If you insist that you only want one task, that's fine. You can
    even#> <b><#lt_add_a_loop_from_loop_ add a loop from '@loop_from_task_name@' back to itself#></b><#lt__The____way_it_works_ . The
    way it works is that we'll ask the user some question, to which he
    answers yes or no. If he answers yes, we'll go back to the same task again,
    if he answers no, we'll continue to finish the process&#151;or
    vice versa. You get to decide that.#>

</if>

<if @tasks:rowcount@ ge 2>
    <#lt_A_loop_always_goes_ba A loop always goes back to some#> <b><#prior_task prior task#></b> <#lt_in_the_process_eg_fro in the process, e.g. from
    '@loop_from_task_name@' to '@loop_to_task_name@'. Whether we loop back
    to '@loop_to_task_name@' or go forward to @loop_next_pretty@ is up to
    the person performing '@loop_from_task_name@'.#> 
    
    <p>
    
    <#We_will_ask_him_a We will ask him a#> <b><#yesno_question yes/no question#></b><#lt__such_as____Approved_ , such as
    'Approved?'. Depending on the answer, we'll go to either
    '@loop_to_task_name@' or @loop_next_pretty@.#>
    
    <p>
    
    <#lt_In_the_list_below_hit In the list below, hit add loop on#> <b><#lt_the_task_you_want_to_ the task you want to loop
    from#></b><#_ie_the , i.e. the#> <b><#last last#></b> <#task_in_the_loop task in the loop.#> 
</if>

<blockquote>
<table cellspacing=0 cellpadding=0 border=0>
<tr><td bgcolor=#cccccc>

<table width="100%" cellspacing=1 cellpadding=4 border=0>
<tr bgcolor=#ffffe4>
<th><#Order Order#></th>
<th><#Task Task#></th>
<th><#Loop Loop#></th>
<th><#Action Action#></th>
</tr>

<multiple name="tasks">
    <tr valign=middle bgcolor=#eeeeee>
    <td align=right>@tasks.rownum@.</td>
    <td align=left>@tasks.task_name@</td>
    <td align=left>

    <if @tasks.loop_to_task_name@ not nil>
	<#lt_Go_to_tasksloop_to_ta Go to @tasks.loop_to_task_name@ if#>
	<if @tasks.loop_answer@ eq "f"><#not not#></if>
	@tasks.loop_question@
    </if>
    <else>&nbsp;</else>

    </td>
    <td align=center>
    
    <if @tasks.loop_to_task_name@ nil>
	(<a href="loop-add?from_transition_key=@tasks.transition_key@"><#add_loop add loop#></a>)
    </if>
    <else>
 	(<a href="loop-delete?from_transition_key=@tasks.transition_key@"><#remove_loop remove loop#></a>)
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
<br><#Hit_Next_when_youre Hit Next when you're#> <b><#done_adding_loops done adding loops#></b>.
</center>
</form>

</master>

