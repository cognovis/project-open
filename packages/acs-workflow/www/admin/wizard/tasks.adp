<master>
<property name="title">Simple Process Wizard Step 2: Tasks for @workflow_name;noquote@</property>
<property name="context">@context;noquote@</property>

<include src="progress-bar" num_completed="1">

<p>

<if @tasks:rowcount@ eq 0>
    <p>The next step in designing your business process is to specify the tasks involved.</p>
</if>

<p>
    During this step, you ignore the loops and just think of <b>the tasks
    that every case must go through</b>. We'll add loops in the next step.
</p>

<if @tasks:rowcount@ eq 0>
    <p><a href="task-add">Add the first task to this process</a></p>
</if>

<if @tasks:rowcount@ gt 0>
    <blockquote>
    <table cellspacing=0 cellpadding=0 border=0>
    <tr><td bgcolor=#cccccc>
    
    <table width="100%" cellspacing=1 cellpadding=4 border=0>
    <tr bgcolor=#ffffe4>
    <th>Order</th>
    <th>Task</th>
    <th>Time</th>
    <th>Action</th>
    </tr>
    
    <multiple name="tasks">
	<tr valign=middle bgcolor=#eeeeee>
	<td align=right>@tasks.rownum@.</td>
	<td align=left><a href="task-edit?transition_key=@tasks.transition_key@">@tasks.task_name@</a></td>
	<td align=right>
	    <if @tasks.task_time@ nil>&nbsp;</if>
	    <else>@tasks.task_time@</else>
        </td>
	<td align=center>(<a href="task-delete?transition_key=@tasks.transition_key@">delete</a>)
	<if @tasks.rownum@ gt 1>
	    (<a href="task-move?transition_key=@tasks.transition_key@">move up</a>)
	</if>
	</td>
	</tr>
    </multiple>

    </table>
    </table>
    </blockquote>
    <a href="task-add">Add another task</a>

    <p>

    <form action="loops" method=post>
    <center>
    <input type=submit value="Next -&gt;">
    <br>Hit Next when you're <b>done adding tasks</b>
    </center>
    </form>
</if>

</master>

