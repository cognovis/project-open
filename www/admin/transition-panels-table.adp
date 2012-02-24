<if @panels:rowcount@ eq 0>
  <blockquote>
    <em>#acs-workflow.lt_No_transitions_define#</em>
  </blockquote>
</if>
<else>
  <table cellspacing="0" cellpadding="0" border="0">
    <tr>
      <td bgcolor="#cccccc">
        <table cellspacing="1" cellpadding="4" border="0">
          <tr valign=middle bgcolor="#ffffe4">
            <th>#acs-workflow.Transition#</th>
            <th>#acs-workflow.Add#</th>
            <th>#acs-workflow.No_#</th>
            <th>#acs-workflow.Header#</th>
<!--
            <th>#acs-workflow.Template_URL#</th>
            <th>#acs-workflow.Options#</th>
-->
            <th>#acs-workflow.Action#</th>
          </tr>
   
          <multiple name="panels">
            <if @panels.rowspan@ gt 0>
              <tr bgcolor="#666666"><td colspan="5"></td></tr>
            </if>
            <tr bgcolor="#eeeeee">
              <if @panels.rowspan@ gt 0>
                <td rowspan="@panels.rowspan@">
                  <a href="@panels.transition_edit_url@">@panels.transition_name@</a>
                </td>
                <td rowspan="@panels.rowspan@" valign="middle">
                  (<a href="@panels.panel_add_url@">#acs-workflow.add_panel#</a>)
                </td>
              </if>
              <td align="right">
                <if @panels.template_url@ not nil>
                  @panels.panel_no@.
                </if>
                <else>&nbsp;</else>
              </td>
              <td>
                <if @panels.template_url@ not nil>
                  <a href="@panels.panel_edit_url@">@panels.header@</a>
                </if>
                <else>&nbsp;</else>
              </td>
<!--
              <td>
                <if @panels.template_url@ not nil>
                  @panels.template_url_pretty@
                </if>
                <else>&nbsp;</else>
              </td>
              <td>
                <if @panels.template_url@ not nil>
                  #acs-workflow.lt_overridepanelsoverrid#
                </if>
                <else>&nbsp;</else>
              </td>
-->
              <td>
                (<a href="@panels.panel_delete_url@">#acs-workflow.delete#</a>)
              </td>
            </tr>
          </multiple>
        </table>
      </td>
    </tr>
  </table>
</else>





