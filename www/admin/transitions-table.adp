<if @transitions:rowcount@ eq 0>
  <blockquote>
    <em>No transitions defined</em>
  </blockquote>
</if>
<else>
  <table cellspacing="0" cellpadding="0" border="0">
    <tr>
      <td bgcolor="#cccccc">
	<table cellspacing="1" cellpadding="4" border="0">
	  <tr valign="middle" bgcolor="#ffffe4">
            <th>No.</th>
            <th>Transition</th>
            <th>Trigger</th>
            <th>Action</th>
	    <th>By Role</th>
	  </tr>
   
	  <multiple name="transitions">
	    <tr bgcolor="#eeeeee">
              <td align="right">@transitions.rownum@.</td>
              <td><a href="@transitions.edit_url@">@transitions.transition_name@</a></td>
              <td align="center">@transitions.trigger_type_pretty@</td>
              <td>
                <if @transitions.delete_url@ not nil>
		  (<a href="@transitions.delete_url@">delete</a>)
		</if>
		<else>&nbsp;</else>
	      </td>
              <td>
                <if @transitions.role_key@ not nil>
                  <a href="@transitions.role_edit_url@">@transitions.role_name@</a>
                </if>
                <else>
                  <if @transitions.trigger_type@ eq "user">
                    <em>Not associated with any role</em> (<a href="@transitions.edit_url@">edit</a>)
                  </if>
                  <else>
                    &nbsp;
                  </else>
                </else>
              </td>
	    </tr>
	  </multiple>
	</table>
      </td>
    </tr>
  </table>
</else>
(<a href="@transition_add_url@">add transition</a>)
