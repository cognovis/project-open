<master>
<property name="title">#acs-workflow.lt_Attributes_for_workfl#</property>
<property name="context">@context;noquote@</property>

<table>
  <tr>
    <td width="10%">&nbsp;</td>
    <td>
      <include src="attributes-table" workflow_key="@workflow_key;noquote@">
    </td>
    <td width="10%">&nbsp;</td>
  </tr>

  <tr><td colspan=3>&nbsp;</td></tr>

  <form action="workflow">
    <input type="hidden" name="workflow_key" value="@workflow_key@">
    <tr bgcolor=#dddddd>
      <td colspan=3 align=right>
	<input type=submit value="Done">
      </td>
    </tr>
  </form>
</table>

</master>

