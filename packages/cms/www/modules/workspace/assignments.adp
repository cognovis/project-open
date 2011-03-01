<table cellspacing=0 cellpadding=4 border=0 width="95%">
<tr bgcolor="#FFFFFF">
  <td>
    <b>Tasks Checked Out By Other Users</b>
  </td>
</tr>

<tr bgcolor="#6699CC"><td>
<table cellspacing=0 cellpadding=4 border=0 width="100%">

<if @locked_tasks:rowcount@ eq 0>
  <tr bgcolor="#99CCFF">
    <td>
  <em>You have no outstanding tasks that have been started by another user.</em>
    </td>
  </tr>
</if>
<else>

<tr bgcolor="#99CCFF">
  <th width="15%">Type</th>
  <th width="30%">Title</th>
  <th width="20%">My Tasks</th>
  <th width="15%">Deadline</th>
  <th width="8%">Checked out by</th>
  <th width="7%">Checked out until</th>
  <th width="5%">&nbsp</th>
</tr>

<multiple name=locked_tasks>
  <if @locked_tasks.rownum@ odd><tr bgcolor="#FFFFFF"></if>
  <else><tr bgcolor="#EEEEEE"></else>

    <td>@locked_tasks.pretty_name@</td>
    <td><a href="../items/index?item_id=@locked_tasks.item_id@">@locked_tasks.title@</a></td>
    <td>@locked_tasks.transition_name@</td>
    <td>@locked_tasks.deadline@</td>
    <td>
      <if @locked_tasks.holding_user_name@ nil>
	&nbsp
      </if>
      <else>@locked_tasks.holding_user_name@</else>
    </td>
    <td>@locked_tasks.hold_timeout@</td>
    <td><a href="../workflow/task-start?task_id=@locked_tasks.task_id@">Steal</a></td>


  </tr>
</multiple>
</else> 
</table>

</td></tr>
</table>



