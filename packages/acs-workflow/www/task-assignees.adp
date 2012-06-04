<master>
<property name="title">#acs-workflow.Reassign_Task#</property>
<property name="context">@context;noquote@</property>

<h3>#acs-workflow.Current_Assignees#</h3>

<ul>

<multiple name="assignees">
    <li>
      <if @assignees.url@ not nil>
        <a href="@assignees.url@">@assignees.name@</a>
      </if>
      <else>
        @assignees.name@
      </else>
      <if @assignees.email@ not nil>(<a href="mailto:@assignees.email@">@assignees.email@</a>)</if>
      (<a href="@assignees.remove_url@">#acs-workflow.remove#</a>)
    </li>
</multiple>

<if @assignees:rowcount@ eq 0>
    <em>#acs-workflow.no_assignees#</em>
</if>

</ul>

(<a href="@task.add_group_url@">#acs-workflow.add_group#</a>)
(<a href="@task.add_person_url@">#acs-workflow.add_person#</a>)

<if @task.this_user_is_assigned_p@ eq 0>
    (<a href="@task.assign_yourself_url@">#acs-workflow.assign_yourself#</a>)
</if>

<h3>#acs-workflow.Effective_Assignees#</h3>

<ul>

<multiple name="effective_assignees">
    <li><a href="@effective_assignees.url@">@effective_assignees.name@</a> (<a href="mailto:@effective_assignees.email@">@effective_assignees.email@</a>)
</multiple>

<if @effective_assignees:rowcount@ eq 0>
    <em>#acs-workflow.lt_no_effective_assignee#</em>
</if>

</ul>

<form method="post" action="@done_action_url@">
 <table width="100%" border="0" cellspacing="0" cellpadding="0">
  @done_export_vars;noquote@
  <tr>
    <td colspan="3" align="left">
      <input type=submit value="Done" />
    </td>
  </tr>
 </table>
</form>

</master>

