<master>
<property name="title">Reassign Task</property>
<property name="context">@context;noquote@</property>

<h3>Current Assignees</h3>

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
      (<a href="@assignees.remove_url@">remove</a>)
    </li>
</multiple>

<if @assignees:rowcount@ eq 0>
    <em>no assignees</em>
</if>

</ul>

(<a href="@task.add_assignee_url@">add assignee</a>)
<if @task.this_user_is_assigned_p@ eq 0>
    (<a href="@task.assign_yourself_url@">assign yourself</a>)
</if>

<h3>Effective Assignees</h3>

<ul>

<multiple name="effective_assignees">
    <li><a href="@effective_assignees.url@">@effective_assignees.name@</a> (<a href="mailto:@effective_assignees.email@">@effective_assignees.email@</a>)
</multiple>

<if @effective_assignees:rowcount@ eq 0>
    <em>no effective assignees</em>
</if>

</ul>

<form method="post" action="@done_action_url@">
 <table width="100%" border="0" cellspacing="0" cellpadding="0">
  @done_export_vars;noquote@
  <tr bgcolor="#dddddd">
    <td colspan="3" align="right">
      <input type=submit value="Done" />
    </td>
  </tr>
 </table>
</form>

</master>