<master src="../../master">
<property name="title">@page_title;noquote@</property>
<h2>@page_title@</h2>
<p>

<if @overdue_tasks:rowcount@ eq 0>
  <i>There are no overdue workflow tasks.</i><p>
</if>
<else>


<table cellspacing=0 cellpadding=4 border=0 width="95%">
<tr bgcolor="#6699CC"><td>

<table cellspacing=0 cellpadding=4 border=0 width="100%">
<tr bgcolor="99CCFF">

  <if @transition@ eq "all">
    <th>Task</th>
  </if>
  <th>Item</th>
  <th>Assigned Party</th>
  <th>Deadline</th>
  <th>Status</th>
</tr>

<multiple name=overdue_tasks>
  <if @overdue_tasks.rownum@ odd><tr bgcolor="#FFFFFF"></if>
  <else><tr bgcolor="#EEEEEE"></else>

  <if @transition@ eq "all">
    <td>
      <a href="overdue-items?transition=@overdue_tasks.transition_key@">
        @overdue_tasks.transition_name@
      </a>
    </td>
  </if>

  <td>
    <a href="../items/index?item_id=@overdue_tasks.item_id@">
      @overdue_tasks.title@
    </a>
  </td>
  <td>
    <a href="user-tasks?party_id=@overdue_tasks.party_id@">
      @overdue_tasks.assigned_party@
    </a>
  </td>
  <td>
    <if @overdue_tasks.deadline_pretty@ nil>&nbsp</if>
    <else>@overdue_tasks.deadline_pretty@</else>
  </td>
  <td>
    <if @overdue_tasks.status@ nil>
      Waiting for a previous task to be completed
    </if>
    <else>@overdue_tasks.status@</else>
  </td>
  </tr>
</multiple>

</table>
</td></tr>
</table>


</else>

<p>
<if @transition_name@ ne "All Tasks">
  <a href="overdue-items">View all outstanding workflow tasks</a>
</if>
