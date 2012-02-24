<master>
<property name="title">#acs-workflow.lt_workflow_namenoquote__1#</property>
<property name="context">@context;noquote@</property>

<!--
Context: [ 
  <multiple name="context_slider">
    <if @context_slider.rownum@ ne 1>|</if>
    <if @context_slider.selected_p@ eq 1><b>@context_slider.title@</b></if>
    <else><a href="@context_slider.url@">@context_slider.title@</a></else>
  </multiple>
]
(<a href="@context_add_url@">#acs-workflow.create_new_context#</a>)
-->

<table>
<tr><td width="10%">&nbsp;</td><td>

<multiple name="tasks">
    <table width="100%" cellspacing="0" cellpadding="0" border="0">
    <tr><td bgcolor="#cccccc">
 
    <table width="100%" cellspacing="1" cellpadding="4" border="0">
    <tr bgcolor="#ffffe4">
    <td><table width="100%" border="0" cellspacing="0" cellpadding="0"><tr><th align="left" valign="middle">#acs-workflow.lt_Task_taskstransition_#</th></tr></table></td>
    </tr>

    <group column="transition_key">
        <tr valign="middle" bgcolor="#eeeeee">
        <td>
            <if @tasks.party_id@ not nil>
		<a href="/shared/community-member?user_id=@tasks.party_id@">@tasks.party_name@</a>
		<if @tasks.party_email@ not nil>(<a href="mailto:@tasks.party_email@">@tasks.party_email@</a>)</if>
		<if @tasks.party_email@ nil>&nbsp;</if>
		&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<small>(<a href="static-assignment-delete?workflow_key=@workflow_key@&context_key=@context_key@&transition_key=@tasks.transition_key@&party_id=@tasks.party_id@">#acs-workflow.remove#</a>)</small>
            </if>
            <if @tasks.party_id@ nil>
	        <em>#acs-workflow.lt_no_static_assignments#</em>
            </if>
	</td>
	</tr>
    </group>

    <form method=get action=static-assignment-add>
	<tr>
	    <td align="right" valign="middle" bgcolor="#ffffe4">
		<if @tasks.user_select_widget@ not nil>
                    <input type="hidden" name="workflow_key" value="@workflow_key@" />
                    <input type="hidden" name="context_key" value="@context_key@" />
                    <input type="hidden" name="transition_key" value="@tasks.transition_key@" />
                    #acs-workflow.lt_Add_assignee_tasksuse# <input type="submit" value="Add" />
                </if>
                <if @tasks.user_select_widget@ nil>
                    <em>#acs-workflow.lt_All_parties_are_alrea#</em>
                </if>
	    </td>
	</tr>
    </form>

    </table>
    </table>
    <p>
</multiple>    

</td><td width="10%">&nbsp;</td>
</tr>

<form action="workflow">
<input type="hidden" name="workflow_key" value="@workflow_key@" />

<tr bgcolor="#dddddd"><td colspan="3" align="right">
<input type="submit" value="Done" />
</td></tr>
</form>
</table>



</master>


