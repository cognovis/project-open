<table border=0 cellpadding=1 cellspacing=0 bgcolor=#FFFFFF width="95%">
<tr bgcolor=#DDDDDD><td>

<if @caseinfo@ not nil>

<table border=0 cellpadding=2 cellspacing=0 width=100% bgcolor=#FFFFFF>
<tr bgcolor=#FFFFFF>
  <th align=left>Workflow</th>
  <th>&nbsp;</th>
</tr>
<tr bgcolor=#FFFFFF>
  <td>Current workflow status:</td>
  <td>@caseinfo.state@</td>
</tr>
<if @caseinfo.state@ eq "Active">
  <if @transinfo@ nil>
    <tr bgcolor=#FFFFFF>
      <td colspan=2>No tasks are current started or enabled</td>
    </tr>
  </if>
  <else>
    <tr bgcolor=#FFFFFF>
      <td>Current task:</td>
      <td>@transinfo.transition_name@
        <if @is_assigned@ eq "yes">
          <if @transinfo.holding_user@ nil>
            (<a href="../workflow/task-finish?task_id=@transinfo.task_id@&return_url=@return_url@">Finish</a>)
          </if>
          <else>
            <if @transinfo.holding_user@ eq @user_id@>
              (<a href="../workflow/task-finish?task_id=@transinfo.task_id@&return_url=@return_url@">Finish</a>)
            </if>
            <else>
              (<a href="../workflow/task-start?task_id=@transinfo.task_id@&return_url=@return_url@">Steal</a> from @transinfo.hold_name@)
            </else>
          </else>
        </if>    
      </td>
    </tr>
  </else>
</if>
</table>

</if>
<else>

  <table border=0 width=95% cellpadding=2 cellspacing=0 >
    <tr><th align=left>Workflow</th></tr>
    <tr><td>
      <a href="../workflow/case-create?item_id=@item_id@">
       Create a workflow for this item.</a>
    </td></tr>
  </table>

</else>

</td></tr>
</table>
