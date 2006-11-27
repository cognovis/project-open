<master>
<property name="title">Add panel</property>
<property name="focus">panel.header</property>
<property name="context">@context;noquote@</property>


<h2>Add Panel</h2>


<form action="task-panel-add-2" name="panel" method="post">
@export_vars;noquote@

<table>
  <tr>
    <th align="right">Header</th>
    <td><input type="text" size="80" name="header" /></td>
  </tr>
  <tr>
    <th align="right">Template URL</th>
    <td>
      <input type="text" size="80" name="template_url" />
      <br>
      (This will typically take the form <code>/packages/<em>package-name</em>/www/<em>template-name</em></code>)
    </td>
  </tr>
  <tr>
    <th align="right">Override default Action panel?</th>
    <td>
      <input type="radio" name="overrides_action_p" value="t" \>Yes  
      <input type="radio" name="overrides_action_p" value="f" checked="checked" \>No
    </td>
  </tr>
  <tr>
    <th align="right">Override both panels?</th>
    <td>
      <input type="radio" name="overrides_both_panels_p" value="t" \>Yes  
      <input type="radio" name="overrides_both_panels_p" value="f" checked="checked" \>No
    </td>
  </tr>
  <tr>
    <th align="right">Only display when task is stared?</th>
    <td>
      <input type="radio" name="only_display_when_started_p" value="t" \>Yes  
      <input type="radio" name="only_display_when_started_p" value="f" checked="checked" \>No
    </td>
  </tr>
  <tr>
    <td colspan="2" align="center">
      <input type="submit" value="Add" \>
      &nbsp; &nbsp; &nbsp; 
      <input type="submit" name="cancel" value="Cancel" \>
    </td>
  </tr>
</table>

</form>

</master>