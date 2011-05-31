<master>
<property name="title">#acs-workflow.Set_Deadline#</property>
<property name="context">@context;noquote@</property>

<form action="case-deadline-set-2" name="deadline">
@export_vars;noquote@
<table>
  <tr>
    <th align="right">#acs-workflow.Task#</th>
    <td>@transition_name;noquote@</td>
  </tr>
  <tr>
    <th align="right">#acs-workflow.Deadline#</th>
    <td>@date_widget;noquote@ </td>
  </tr>
  <tr>
    <td>&nbsp;</td>
  </tr>
  <tr>
    <td>&nbsp;</td>
    <td align="center">
      <input type="submit" name="submit" value="Set Deadline" />
      &nbsp;&nbsp;&nbsp;
      <input type="submit" name="cancel" value="Cancel" />
    </td>
  </tr>
</table>
</form>

</master>
