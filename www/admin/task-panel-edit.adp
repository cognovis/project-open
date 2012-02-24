<master>
<property name="title">#acs-workflow.Edit_panel#</property>
<property name="context">@context;noquote@</property>
<property name="focus">panel.header</property>

<form action="task-panel-edit-2" name="panel" method="post">
@panel.export_vars;noquote@

<table>
  <tr>
    <th align="right">#acs-workflow.Header#</th>
    <td><input type="text" size="80" name="header" value="@panel.header@" /></td>
  </tr>
  <tr>
    <th align="right">#acs-workflow.Template_URL#</th>
    <td>
      <input type="text" size="80" name="template_url" value="@panel.template_url@" /><br />
      #acs-workflow.lt_This_will_typically_t# <code>/packages/<em>package-name</em>/www/<em>template-name</em></code>)
    </td>
  </tr>
  <tr>
    <th align="right">#acs-workflow.lt_Override_default_Acti#</th>
    <td>
      <input type="radio" name="overrides_action_p" value="t" <%=[ad_decode $panel(overrides_action_p) "t" "checked=\"checked\"" ""]%> #acs-workflow.Yes_1#  
      <input type="radio" name="overrides_action_p" value="f" <%=[ad_decode $panel(overrides_action_p) "f" "checked=\"checked\"" ""]%> #acs-workflow.No_2#
    </td>
  </tr>
  <tr>
    <th align="right">#acs-workflow.Override_both_panels#</th>
    <td>
      <input type="radio" name="overrides_both_panels_p" value="t" <%=[ad_decode $panel(overrides_both_panels_p) "t" "checked=\"checked\"" ""]%> #acs-workflow.Yes_1#  
      <input type="radio" name="overrides_both_panels_p" value="f" <%=[ad_decode $panel(overrides_both_panels_p) "f" "checked=\"checked\"" ""]%> #acs-workflow.No_2#
    </td>
  </tr>
  <tr>
    <th align="right">#acs-workflow.lt_Only_display_when_tas#</th>
    <td>
      <input type="radio" name="only_display_when_started_p" value="t" <%=[ad_decode $panel(only_display_when_started_p) "t" "checked=\"checked\"" ""]%> #acs-workflow.Yes_2#  
      <input type="radio" name="only_display_when_started_p" value="f" <%=[ad_decode $panel(only_display_when_started_p) "f" "checked=\"checked\"" ""]%> #acs-workflow.No_3#
    </td>
  </tr>
  <tr>
    <td colspan="2" align="center">
      <input type="submit" value="Update" \>
      &nbsp; &nbsp; &nbsp; 
      <input type="submit" name="cancel" value="Cancel" \>
    </td>
  </tr>
</table>

</form>

</master>
