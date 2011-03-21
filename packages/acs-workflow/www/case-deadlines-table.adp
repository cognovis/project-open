<table cellspacing="0" cellpadding="0" border="0">
  <tr>
    <td bgcolor="#cccccc">
      <table width="100%" cellspacing="1" cellpadding="4" border="0">
        <tr valign="middle" bgcolor="#ffffe4">
          <th>Task</th>
          <th>Deadline</th>
          <th>Remove</th>
          <th>Edit</th>
        </tr>
        <multiple name="deadlines">
          <tr bgcolor="#eeeeee">
            <td>
              @deadlines.transition_name@
            </td>
            <td>
              <if @deadlines.deadline_pretty@ not nil>
                @deadlines.deadline_pretty@
              </if>
              <else>
                <em>no deadline</em>
              </else>
            </td>
            <td align="center">
              <if @deadlines.remove_url@ not nil>
                (<a href="@deadlines.remove_url@">remove</a>)
              </if>
              <else>&nbsp;</else>
            </td>
            <td align="center">
              <if @deadlines.edit_url@ not nil>
                (<a href="@deadlines.edit_url@">edit</a>)
              </if>
              <else>&nbsp;</else>
            </td>
          </tr>
        </multiple>
        <if @deadlines:rowcount@ eq 0>
          <tr>
            <td>
              <em>No transitions</em>
            </td>
          </tr>
        </if>
      </table>
    </td>
  </tr>
</table>
