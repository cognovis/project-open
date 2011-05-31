<master>
<property name="title">#acs-workflow.lt_Case_caseobject_namen#</property>
<property name="context">@context;noquote@</property>

<h3>#acs-workflow.All_Tasks#</h3>
<table border=1>
<tr><th>#acs-workflow.State#</th><th>#acs-workflow.Name#</th></tr>

<multiple name="tasks">
    <tr><td>@tasks.state@</td><td><a href="../task?task_id=@tasks.task_id@">@tasks.transition_key@</a></td></tr>
</multiple>
<if @tasks:rowcount@ eq 0>
    <tr><td><em>#acs-workflow.no_tasks#</em></td></tr>
</if>

</table>

<h3>#acs-workflow.All_Attributes#</h3>

<table border=1>
<tr><th>#acs-workflow.Name#</th><th>#acs-workflow.Value#</th></tr>
<multiple name="attributes">
    <tr><td>@attributes.name@</td><td>@attributes.value@</td></tr>
</multiple>
<if @tasks:rowcount@ eq 0>
    <tr><td><em>#acs-workflow.no_attributes#</em></td></tr>
</if>
</table>

<h3>#acs-workflow.Tokens#</h3>

<h4>#acs-workflow.Live_Tokens#</h4>
<ul>
<multiple name="live_tokens">
    <li>#acs-workflow.lt_token_in_place_live_t#
    <if @live_tokens.locked_task_id@ not nil>
	 #acs-workflow.lt_held_by_task_live_tok#
    </if>
</multiple>
<if @live_tokens:rowcount@ eq 0>
    <em>#acs-workflow.no_tokens#</em>
</if>
</ul>

<h4>#acs-workflow.Dead_Tokens#</h4>
<table border=1>
<tr><th>#acs-workflow.Place#</th><th>#acs-workflow.State#</th><th>#acs-workflow.Produced#</th><th>#acs-workflow.Locked#</th><th>#acs-workflow.Consumed#</th><th>#acs-workflow.Canceled#</th><th>#acs-workflow.Task#</th></tr>
<multiple name="dead_tokens">
    <tr><td>@dead_tokens.place_key@</td><td>@dead_tokens.state@</td>
    <td><small>@dead_tokens.produced_date_pretty@</small></td><td><small>@dead_tokens.locked_date_pretty@</small></td>
    <td><small>@dead_tokens.consumed_date_pretty@</small></td><td><small>@dead_tokens.canceled_date_pretty@</small></td>
    <td>@dead_tokens.locked_task_id@</td></tr>
</multiple>
<if @dead_tokens:rowcount@ eq 0>
    <tr><td><em>#acs-workflow.no_tokens#</em></td></tr>
</if>
</table>


<h3>#acs-workflow.lt_All_Enabled_Transitio#</h3>
<ul>
<multiple name="enabled_transitions">
    <li>@enabled_transitions.transition_name@ (@enabled_transitions.trigger_type@)
    <if @enabled_transitions.trigger_type@ ne "user">
	 (<a href="transition-fire?case_id=@case.case_id@&transition_key=@enabled_transitions.transition_key@">#acs-workflow.fire#</a>)
    </if>
</multiple>
<if @enabled_transitions:rowcount@ eq 0>
    <em>#acs-workflow.lt_no_enabled_transition#</em>
</if>
</ul>

<h3>#acs-workflow.Journal#</h3>

<include src="../journal" case_id="@case.case_id;noquote@">

</master>


