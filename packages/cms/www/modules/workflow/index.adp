<master src="../../master">
<property name="title">@page_title;noquote@</property>

<script language=javascript>
  top.treeFrame.setCurrentFolder('@mount_point@', '@id@', '@parent_id@');
</script> 
  <h2>@page_title@</h2>
  <p>


  <table cellspacing=0 cellpadding=4 border=0 width="95%">
  <tr bgcolor="#FFFFFF"><td>
    <b>Workflow Items by Task</b>
  </td></tr>

  <tr bgcolor="#6699CC"><td>

  <table cellspacing=0 cellpadding=5 border=0 width="100%">
    <tr bgcolor="99CCFF">
      <if @transitions:rowcount@ eq 0>
        <td><em>There are no publishing workflows.</em></td>
      </if>
      <else>

      <th width="40%">Workflow State</th>
      <th width="15%">Workflow Items</th>
      <th width="15%">Active Items</th>
      <th width="15%">Checked Out Items</th>
      <th width="15%">Overdue Items</th>

    </tr>

      <multiple name=transitions>
      <if @transitions.rownum@ odd><tr bgcolor="#FFFFFF"></if>
      <else><tr bgcolor="#EEEEEE"></else>
        <td>
          <a href="workflow?transition=@transitions.transition_key@">
            @transitions.transition_name@
          </a>
        </td>
        <td align=center>@transitions.transition_count@</td>
        <td align=center>@transitions.active_count@</td>
	<td align=center>@transitions.checkout_count@</td>
        <td align=center>
	  <if @transitions.overdue_count@ gt 0>
            <a href="overdue-items?transition=@transitions.transition_key@">@transitions.overdue_count@</a>
          </if>
	  <else>
	    @transitions.overdue_count@
	  </else>
        </td>



      </tr>
      </multiple>

      <tr bgcolor="CCCCCC">
        <td><b>Total</b></td>
        <td align=center><b>@wf_stats.total_count@</b></td>
        <td align=center><b>@wf_stats.active_count@</b></td>
	<td align=center><b>@wf_stats.checkout_count@</b></td>
        <td align=center><b>@wf_stats.overdue_count@</b></td>

    </else>
    </tr>

  </table>

  </td></tr>
  </table>

  </else>



  <p>
  <table cellspacing=0 cellpadding=4 border=0 width="95%">
    <tr bgcolor="#FFFFFF"><td>
      <b>Workflow Items by Assigned Parties</b>
    </td></tr>

    <tr bgcolor="#6699CC"><td>

    <table cellspacing=0 cellpadding=4 border=0 width="100%">
      <tr bgcolor="#99CCFF">
	<if @user_tasks:rowcount@ eq 0>
          <td><em>There are no publishing workflows.</em></td></tr>
        </if>
        <else>

        <th width="40%">Assigned Party</th>
        <th width="15%">Workflow Items</th>
	<th width="15%">Active Items</th>
	<th width="15%">Checked Out Items</th>
	<th width="15%">Overdue Items</th>
      </tr>

      <multiple name=user_tasks>
      <if @user_tasks.rownum@ odd><tr bgcolor="#FFFFFF"></if>
      <else><tr bgcolor="#EEEEEE"></else>
        <td>
          <a href="user-tasks?party_id=@user_tasks.person_id@">
            @user_tasks.first_names@ @user_tasks.last_name@
          </a>
        </td>
        <td align=center>@user_tasks.transition_count@</td>
	<td align=center>@user_tasks.active_count@</td>
	<td align=center>@user_tasks.checkout_count@</td>
	<td align=center>
          <a href="overdue-item">@user_tasks.overdue_count@</a>
        </td>
      </tr>
      </multiple>
    </else>
    </table>

    </td></tr>
    </table>


