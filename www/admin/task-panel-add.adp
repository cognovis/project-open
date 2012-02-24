<master>
<property name="title">#acs-workflow.Add_panel#</property>
<property name="focus">panel.header</property>
<property name="context">@context;noquote@</property>


<h2>#acs-workflow.Add_Panel#</h2>


<form action="task-panel-add-2" name="panel" method="post">
@export_vars;noquote@

<table>
  <tr>
    <th align="right">#acs-workflow.Header#</th>
    <td><input type="text" size="80" name="header" /></td>
  </tr>
  <tr>
    <th align="right">#acs-workflow.Template_URL#</th>
    <td>
      <input type="text" size="80" name="template_url" />
      <br>
      #acs-workflow.lt_This_will_typically_t# <code>#acs-workflow.packages#<em>#acs-workflow.package-name#</em>#acs-workflow.www#<em>#acs-workflow.template-name#</em></code>)
    </td>
  </tr>
  <tr>
    <th align="right">#acs-workflow.lt_Override_default_Acti#</th>
    <td>
      <input type="radio" name="overrides_action_p" value="t" \>#acs-workflow.Yes#  
      <input type="radio" name="overrides_action_p" value="f" checked="checked" \>#acs-workflow.No_1#
    </td>
  </tr>
  <tr>
    <th align="right">#acs-workflow.Override_both_panels#</th>
    <td>
      <input type="radio" name="overrides_both_panels_p" value="t" \>#acs-workflow.Yes#  
      <input type="radio" name="overrides_both_panels_p" value="f" checked="checked" \>#acs-workflow.No_1#
    </td>
  </tr>
  <tr>
    <th align="right">#acs-workflow.lt_Only_display_when_tas#</th>
    <td>
      <input type="radio" name="only_display_when_started_p" value="t" \>#acs-workflow.Yes#  
      <input type="radio" name="only_display_when_started_p" value="f" checked="checked" \>#acs-workflow.No_1#
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
