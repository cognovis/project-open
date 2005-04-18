<master src="../../master">
<property name="title">@page_title;noquote@</property>
<h2>@page_title@</h2>
<p>



<table cellspacing=0 cellpadding=4 border=0 width="95%">
<tr bgcolor="#FFFFFF">
  <td>
    <b>Active Tasks</b>
  </td>
</tr>

<tr bgcolor="#6699CC"><td>
<table cellspacing=0 cellpadding=4 border=0 width="100%">

  <if @active_tasks:rowcount@ eq 0>
    <tr bgcolor="#99CCFF"><td>
      <em>There are no active tasks.</em>
    </td></tr>
  </if>
  <else>
    <tr bgcolor="#99CCFF">
      <if @transition@ eq "all">
        <th width="15%">Task</th>
      </if>
      <th>Item</th>
      <th>Assigned Party</th>
      <th>Deadline</th>
      <th>Status</th>
    </tr>

    <multiple name=active_tasks>
    <if @active_tasks.rownum@ odd><tr bgcolor="#FFFFFF"></if>
    <else><tr bgcolor="#EEEEEE"></else>
      <if @transition@ eq "all">
        <td>
          <a href="workflow?transition=@active_tasks.transition_key@">
            @active_tasks.transition_name@
          </a>
	</td>
      </if>
      <td>
        <a href="../items/index?item_id=@active_tasks.item_id@">
          @active_tasks.title@
        </a>
      </td>
      <td>
        <if @active_tasks.assigned_party@ nil>&nbsp</if>
        <else>
  	  <a href="user-tasks?party_id=@active_tasks.party_id@">
    	    @active_tasks.assigned_party@
	  </a>
        </else>
      </td>
      <td>
        <if @active_tasks.deadline_pretty@ nil>&nbsp</if>
        <else>
          <if @active_tasks.is_overdue@ eq t>
            <font color="red">@active_tasks.deadline_pretty@</font>
          </if>
          <else>
            @active_tasks.deadline_pretty@
          </else>
        </else>
      </td>

      <td>
        <table>
	<tr><td>
        Activated on @active_tasks.enabled_date_pretty@</td></tr>
        <if @active_tasks.state@ eq "started">
	  <tr>
	  <td><b>Checked Out</b> by 
          <a href="user-tasks?user_id=@active_tasks.holding_user@">
	    @active_tasks.holding_user_name@
          </a> 
          on @active_tasks.started_date_pretty@ until 
	  @active_tasks.hold_timeout_pretty@</td></tr>
        </if>
        </table>
      </td>
    </tr>
    </multiple>

  </else>
</table>

</td></tr>
</table>

<p>


<if @awaiting_tasks:rowcount@ gt 0>

<table cellspacing=0 cellpadding=4 border=0 width="95%">
<tr bgcolor="#FFFFFF">
  <td>
    <b>Awaiting Tasks</b>
  </td>
</tr>

<tr bgcolor="#6699CC"><td>
<table cellspacing=0 cellpadding=4 border=0 width="100%">

    <tr bgcolor="#99CCFF">
      <if @transition@ eq "all">
        <th>Task</th>
      </if>
      <th>Item</th>
      <th>Assigned Party</th>
      <th>Deadline</th>
    </tr>

    <multiple name=awaiting_tasks>
    <if @awaiting_tasks.rownum@ odd><tr bgcolor="#FFFFFF"></if>
    <else><tr bgcolor="#EEEEEE"></else>
      <if @transition@ eq "all">
        <td>
	 <a href="workflow?transition=@awaiting_tasks.transition_key@">
            @awaiting_tasks.transition_name@
	 </a>
	</td>
      </if>
      <td>
        <a href="../items/index?item_id=@awaiting_tasks.item_id@">
          @awaiting_tasks.title@
        </a>
      </td>
      <td>
        <if @awaiting_tasks.assigned_party@ nil>&nbsp</if>
        <else>
	  <a href="user-tasks?party_id=@awaiting_tasks.party_id@">
	    @awaiting_tasks.assigned_party@
	  </a>
	</else>
      </td>
      <td>
        <if @awaiting_tasks.deadline_pretty@ nil>&nbsp</if>
        <else>
          <if @awaiting_tasks.is_overdue@ eq t>
            <font color="red">@awaiting_tasks.deadline_pretty@</font>
          </if>
          <else>
            @awaiting_tasks.deadline_pretty@
          </else>
        </else>
      </td>

    </tr>
    </multiple>

</table>

</td></tr>
</table>
</if>

<p>
<if @transition_name@ ne "All Tasks">
  <a href="workflow">View all workflow tasks</a>
</if>


