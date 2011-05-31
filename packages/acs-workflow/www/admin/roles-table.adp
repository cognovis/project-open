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
            <th>&nbsp;</th>
            <th>&nbsp;</th>
            <th>#acs-workflow.No#</th>
            <th>#acs-workflow.Role#</th>
	    <th>#acs-workflow.Action#</th>
            <th>#acs-workflow.Transitions#</th>
	  </tr>
   
	  <multiple name="roles">
	    <tr bgcolor="#eeeeee">
              <td>
                <if @roles.move_up_url@ not nil>
                  <a href="@roles.move_up_url@"><img src="up.gif" border="0" alt="Move up" width="18" height="15"></a>
                </if>
                <else>&nbsp;</else>
              </td>
              <td>
                <if @roles.move_down_url@ not nil>
                  <a href="@roles.move_down_url@"><img src="down.gif" border="0" alt="Move down" width="18" height="15"></a>
                </if>
                <else>&nbsp;</else>
              </td>
              <td align="right">@roles.role_no@.</td>
              <td><a href="@roles.edit_url@">@roles.role_name@</a></td>
	      <td>
		<if @roles.delete_url@ not nil>
                  <small>(<a href="@roles.delete_url@">#acs-workflow.delete#</a>)</small>
		</if>
		<else>&nbsp;</else>
	      </td>
              <td>
                <if @roles.transition_name@ not nil>
		  <group column="role_key">
		    <li><a href="@roles.transition_edit_url@">@roles.transition_name@</a></li>
		  </group>
                </if>
                <else>
                  <em>#acs-workflow.lt_No_transitions_belong#</em>
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

