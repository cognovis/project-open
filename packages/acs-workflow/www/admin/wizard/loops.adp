<master>
<property name="title">Simple Process Wizard Step 3: Loops for @workflow_name;noquote@</property>
<property name="context">@context;noquote@</property>

<include src="progress-bar" num_completed="2">

<p>

<if @tasks:rowcount@ eq 0>
    You haven't defined any tasks yet. 
    Please <a href="tasks">go back and define some tasks</a> now.
</if>

<if @tasks:rowcount eq 1>
    You only have <b>one task defined</b>. That's barely
    enough to call a <em>process</em>, so you probably want to <a
    href="tasks">go back and define more tasks</a>. 

    <p>

    If you insist that you only want one task, that's fine. You can
    even <b>add a loop from '@loop_from_task_name@' back to itself</b>. The
    way it works is that we'll ask the user some question, to which he
    answers yes or no. If he answers yes, we'll go back to the same task again,
    if he answers no, we'll continue to finish the process&#151;or
    vice versa. You get to decide that.

</if>

<if @tasks:rowcount@ ge 2>
    A loop always goes back to some <b>prior task</b> in the process, e.g. from
    '@loop_from_task_name@' to '@loop_to_task_name@'. Whether we loop back
    to '@loop_to_task_name@' or go forward to @loop_next_pretty@ is up to
    the person performing '@loop_from_task_name@'. 
    
    <p>
    
    We will ask him a <b>yes/no question</b>, such as
    'Approved?'. Depending on the answer, we'll go to either
    '@loop_to_task_name@' or @loop_next_pretty@.
    
    <p>
    
    In the list below, hit add loop on <b>the task you want to loop
    from</b>, i.e. the <b>last</b> task in the loop. 
</if>

<blockquote>
<table cellspacing=0 cellpadding=0 border=0>
<tr><td bgcolor=#cccccc>

<table width="100%" cellspacing=1 cellpadding=4 border=0>
<tr bgcolor=#ffffe4>
<th>Order</th>
<th>Task</th>
<th>Loop</th>
<th>Action</th>
</tr>

<multiple name="tasks">
    <tr valign=middle bgcolor=#eeeeee>
    <td align=right>@tasks.rownum@.</td>
    <td align=left>@tasks.task_name@</td>
    <td align=left>

    <if @tasks.loop_to_task_name@ not nil>
	Go to @tasks.loop_to_task_name@ if
	<if @tasks.loop_answer@ eq "f">not</if>
	@tasks.loop_question@
    </if>
    <else>&nbsp;</else>

    </td>
    <td align=center>
    
    <if @tasks.loop_to_task_name@ nil>
	(<a href="loop-add?from_transition_key=@tasks.transition_key@">add loop</a>)
    </if>
    <else>
 	(<a href="loop-delete?from_transition_key=@tasks.transition_key@">remove loop</a>)
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
<br>Hit Next when you're <b>done adding loops</b>.
</center>
</form>

</master>
