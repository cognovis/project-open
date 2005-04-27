<master>
<property name="title">Case: @case.object_name;noquote@ (@case.state;noquote@)</property>
<property name="context">@context;noquote@</property>

<h3>All Tasks</h3>
<table border=1>
<tr><th>State</th><th>Name</th></tr>

<multiple name="tasks">
    <tr><td>@tasks.state@</td><td><a href="../task?task_id=@tasks.task_id@">@tasks.transition_key@</a></td></tr>
</multiple>
<if @tasks:rowcount@ eq 0>
    <tr><td><em>no tasks</em></td></tr>
</if>

</table>

<h3>All Attributes</h3>

<table border=1>
<tr><th>Name</th><th>Value</th></tr>
<multiple name="attributes">
    <tr><td>@attributes.name@</td><td>@attributes.value@</td></tr>
</multiple>
<if @tasks:rowcount@ eq 0>
    <tr><td><em>no attributes</em></td></tr>
</if>
</table>

<h3>Tokens</h3>

<h4>Live Tokens</h4>
<ul>
<multiple name="live_tokens">
    <li>token in place @live_tokens.place_key@ (@live_tokens.state@)
    <if @live_tokens.locked_task_id@ not nil>
	 (held by task @live_tokens.locked_task_id@)
    </if>
</multiple>
<if @live_tokens:rowcount@ eq 0>
    <em>no tokens</em>
</if>
</ul>

<h4>Dead Tokens</h4>
<table border=1>
<tr><th>Place</th><th>State</th><th>Produced</th><th>Locked</th><th>Consumed</th><th>Canceled</th><th>Task</th></tr>
<multiple name="dead_tokens">
    <tr><td>@dead_tokens.place_key@</td><td>@dead_tokens.state@</td>
    <td><small>@dead_tokens.produced_date_pretty@</small></td><td><small>@dead_tokens.locked_date_pretty@</small></td>
    <td><small>@dead_tokens.consumed_date_pretty@</small></td><td><small>@dead_tokens.canceled_date_pretty@</small></td>
    <td>@dead_tokens.locked_task_id@</td></tr>
</multiple>
<if @dead_tokens:rowcount@ eq 0>
    <tr><td><em>no tokens</em></td></tr>
</if>
</table>


<h3>All Enabled Transitions</h3>
<ul>
<multiple name="enabled_transitions">
    <li>@enabled_transitions.transition_name@ (@enabled_transitions.trigger_type@)
    <if @enabled_transitions.trigger_type@ ne "user">
	 (<a href="transition-fire?case_id=@case.case_id@&transition_key=@enabled_transitions.transition_key@">fire</a>)
    </if>
</multiple>
<if @enabled_transitions:rowcount@ eq 0>
    <em>no enabled transitions</em>
</if>
</ul>

<h3>Journal</h3>

<include src="../journal" case_id="@case.case_id;noquote@">

</master>

