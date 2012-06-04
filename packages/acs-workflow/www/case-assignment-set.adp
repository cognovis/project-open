<master>
<property name="title">#acs-workflow.lt_Assign_role_namenoquo#</property>
<property name="context">@context;noquote@</property>

<form action="case-assignment-set-2" name="assignment">
@export_vars;noquote@
<table>
  <tr>
    <th align="right">#acs-workflow.Role#</th>
    <td>@role_name@</td>
  </tr>
  <tr>
    <th align="right">#acs-workflow.Assignments#</th>
    <td>@widget;noquote@</td>
  </tr>
  <tr>
    <td>&nbsp;</td>
  </tr>
  <tr>
    <td>&nbsp;</td>
    <td align="center">
      <input type="submit" name="submit" value="Set Assignments" />
      &nbsp; &nbsp; &nbsp;
      <input type="submit" name="cancel" value="Cancel" />
    </td>
  </tr>
</table>
</form>

</master>
