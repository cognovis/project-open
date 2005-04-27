<if @roles:rowcount@ eq 0>
  <blockquote>
    <em>No roles defined</em>
  </blockquote>
</if>
<else>
  <table cellspacing="0" cellpadding="0" border="0">
    <tr>
      <td bgcolor="#cccccc">
	<table cellspacing="1" cellpadding="4" border="0">
	  <tr valign="middle" bgcolor="#ffffe4">
            <th>No.</th>
            <th>Role</th>
	    <th>Action</th>
            <th>Static Assignment</th>
            <th>Manual Assignment</th>
            <th>Programmatic Assignment</th>
	  </tr>
   
	  <multiple name="roles">
	    <tr bgcolor="#eeeeee">
              <td align="right">@roles.rownum@.</td>
              <td>@roles.role_name@</td>
	      <td>
		<if @roles.delete_url@ not nil>
                  <small>(<a href="@roles.delete_url@">delete</a>)</small>
		</if>
		<else>&nbsp;</else>
	      </td>
              <td align="center">
                <if @roles.is_static_p@ eq 1>
                  <b>Static</b>
                </if>
                <else>
                  &nbsp;
                </else>
              </td>
              <td align="left">
                <if @roles.assigning_transition_key@ nil>
                  <center><small>(<a href="@roles.manual_url@">change to manual</a>)</small></center>
                </if>
                <else>
                  <center>
                    <b>Manual</b>
                    <br><small>Assigned by these transitions:</small>
                  </center>
                  <group column="role_key">
                    <li>@roles.assigning_transition_name@</li>
                  </group>
                  <br />(<a href="@roles.manual_url@">assign by another transition</a>)
                </else>
              </td>
              <td align="center">
                <if @roles.assignment_callback@ nil>
                  <small>(<a href="@roles.programmatic_url@">change to programmatic</a>)</small>
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
(<a href="@role_add_url@">add role</a>)


