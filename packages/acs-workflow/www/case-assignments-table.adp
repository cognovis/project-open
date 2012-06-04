<table cellspacing="0" cellpadding="0" border="0">
  <tr>
    <td bgcolor="#cccccc">
      <table width="100%" cellspacing="1" cellpadding="4" border="0">
        <tr valign="middle" bgcolor="#ffffe4">
          <th>#acs-workflow.Role#</th>
          <th>#acs-workflow.Assignees#</th>
          <th>#acs-workflow.Action#</th>
        </tr>
        <multiple name="manual_assignments">
          <tr bgcolor="#eeeeee">
            <td>@manual_assignments.role_name@</td>
            <td>
              <if @manual_assignments.party_id@ not nil>
                <group column="role_key">
                  <li>
                    <if @manual_assignments.url@ not nil>
                      <a href="@manual_assignments.url@">@manual_assignments.name@</a>
                    </if>
                    <else>
                      @manual_assignments.name@
                    </else>
                    <if @manual_assignments.email@ not nil>
                      (<a href="mailto:@manual_assignments.email@">@manual_assignments.email@</a>)
                    </if>
                    <if @manual_assignments.remove_url@ not nil>
                      (<a href="@manual_assignments.remove_url@">#acs-workflow.remove#</a>)
                    </if>
                  </li>
                </group>
              </if>
              <else>
                <em>#acs-workflow.Unassigned#</em>
              </else>
            </td>
            <td align="center">
              <if @manual_assignments.edit_url@ not nil>
                (<a href="@manual_assignments.edit_url@">#acs-workflow.edit#</a>)
              </if>
            </td>
          </tr>
        </multiple>
      </table>
    </td>
  </tr>
</table>



