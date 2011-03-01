<master src="../../master">
<property name="title">My Work Items</property>

<script language=javascript>
  top.treeFrame.setCurrentFolder('@mount_point@', '@id@', '@parent_id@');
</script> 

<h2>My Tasks</h2>


<table cellspacing=0 cellpadding=4 border=0 width="95%">
<tr bgcolor="#FFFFFF">
  <td>
    <b>My Tasks</b>
  </td>
</tr>


<tr bgcolor="#6699CC"><td>
<table cellspacing=0 cellpadding=4 border=0 width="100%">

<if @items:rowcount@ eq 0>
  <tr bgcolor="#99CCFF">
    <td><em>You have no outstanding tasks.</em></td>
  </tr>
</if>
<else>

<tr bgcolor="#99CCFF">
  <th width="15%">Type</th>
  <th width="30%">Title</th>
  <th width="20%">My Tasks</th>
  <th width="15%">Deadline</th>
  <th width="10%">&nbsp;</th>
  <th width="5%">&nbsp;</th>
  <th width="5%">&nbsp;</th>
</tr>

<multiple name=items>
  <if @items.rownum@ odd><tr bgcolor="#FFFFFF"></if>
  <else><tr bgcolor="#EEEEEE"></else>

    <td>@items.pretty_name@</td>
    <td>
      <if @items.title@ not nil>
        <a href="../items/index?item_id=@items.item_id@">@items.title@</a>
      </if>
      <else>&nbsp;</else>
    </td>
    <td>@items.transition_name@</td>
    <td>@items.deadline@</td>

    <td>
      <if @items.state@ ne "started">
        <a href="../workflow/task-start?task_id=@items.task_id@">
	  Checkout
	</a>
      </if>
      <else>
        <if @items.holding_user@ ne @user_id@>
          <a href="../workflow/task-start?task_id=@items.task_id@">
	    Steal
	  </a>         
        </if>
        <else>
	  <a href="../workflow/task-checkin?task_id=@items.task_id@">
	    Check-in
	  </a>
        </else>
      </else>
    </td>


    <td>
      <if @items.approve_string@ not nil>
        <a href="../workflow/task-finish?task_id=@items.task_id@">
	  @items.approve_string@
	</a>
      </if>
      <else>
	&nbsp;        
      </else>
    </td>

    <td>
      <if @items.can_reject@ eq t>
        <a href="../workflow/task-reject?task_id=@items.task_id@">
	  Reject
	</a>
      </if>
      <else>
	&nbsp;
      </else>
    </td>

  </tr>
</multiple>
</else> 

</table>
</td></tr>
</table>



<p>

<include src="assignments">
<p>
