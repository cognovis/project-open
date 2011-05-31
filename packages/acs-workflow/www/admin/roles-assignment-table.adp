<if @roles:rowcount@ eq 0>
  <blockquote>
    <em>#acs-workflow.No_roles_defined#</em>
  </blockquote>
</if>
<else>
  <table cellspacing="0" cellpadding="0" border="0">
    <tr>
      <td bgcolor="#cccccc">
	<table cellspacing="1" cellpadding="4" border="0">
	  <tr valign="middle" bgcolor="#ffffe4">
            <th>#acs-workflow.No#</th>
            <th>#acs-workflow.Role#</th>
	    <th>#acs-workflow.Action#</th>
            <th>#acs-workflow.Static_Assignment#</th>
            <th>#acs-workflow.Manual_Assignment#</th>
            <th>#acs-workflow.lt_Programmatic_Assignme#</th>
	  </tr>
   
	  <multiple name="roles">
	    <tr bgcolor="#eeeeee">
              <td align="right">@roles.rownum@.</td>
              <td>@roles.role_name@</td>
	      <td>
		<if @roles.delete_url@ not nil>
                  <small>(<a href="@roles.delete_url@">#acs-workflow.delete#</a>)</small>
		</if>
		<else>&nbsp;</else>
	      </td>
              <td align="center">
                <if @roles.is_static_p@ eq 1>
                  <b>#acs-workflow.Static#</b>
                </if>
                <else>
                  &nbsp;
                </else>
              </td>
              <td align="left">
                <if @roles.assigning_transition_key@ nil>
                  <center><small>(<a href="@roles.manual_url@">#acs-workflow.change_to_manual#</a>)</small></center>
                </if>
                <else>
                  <center>
                    <b>#acs-workflow.Manual#</b>
                    <br><small>#acs-workflow.lt_Assigned_by_these_tra#</small>
                  </center>
                  <group column="role_key">
                    <li>@roles.assigning_transition_name@</li>
                  </group>
                  <br />(<a href="@roles.manual_url@">#acs-workflow.lt_assign_by_another_tra#</a>)
                </else>
              </td>
              <td align="center">
                <if @roles.assignment_callback@ nil>
                  <small>(<a href="@roles.programmatic_url@">#acs-workflow.lt_change_to_programmati#</a>)</small>
                </if>
                <else>
                  @roles.assignment_callback@
                </else>
              </td>
	    </tr>
	  </multiple>
	</table>
      </td>
    </tr>
  </table>
</else>
(<a href="@role_add_url@">#acs-workflow.add_role#</a>)



