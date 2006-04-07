<master>
<property name="title">Edit panel</property>
<property name="context">@context;noquote@</property>
<property name="focus">panel.header</property>

<form action="task-panel-edit-2" name="panel" method="post">
@panel.export_vars;noquote@

<table>
  <tr>
    <th align="right">Header</th>
    <td><input type="text" size="80" name="header" value="@panel.header@" /></td>
  </tr>
  <tr>
    <th align="right">Template URL</th>
    <td>
      <input type="text" size="80" name="template_url" value="@panel.template_url@" /><br />
      (This will typically take the form <code>/packages/<em>package-name</em>/www/<em>template-name</em></code>)
    </td>
  </tr>
  <tr>
    <th align="right">Override default Action panel?</th>
    <td>
      <input type="radio" name="overrides_action_p" value="t" <%=[ad_decode $panel(overrides_action_p) "t" "checked=\"checked\"" ""]%> />Yes  
      <input type="radio" name="overrides_action_p" value="f" <%=[ad_decode $panel(overrides_action_p) "f" "checked=\"checked\"" ""]%> />No
    </td>
  </tr>
  <tr>
    <th align="right">Only display when task is stared?</th>
    <td>
      <input type="radio" name="only_display_when_started_p" value="t" <%=[ad_decode $panel(only_display_when_started_p) "t" "checked=\"checked\"" ""]%> \>Yes  
      <input type="radio" name="only_display_when_started_p" value="f" <%=[ad_decode $panel(only_display_when_started_p) "f" "checked=\"checked\"" ""]%> \>No
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