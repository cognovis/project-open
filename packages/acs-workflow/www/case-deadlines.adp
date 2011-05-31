<master>
<property name="title">#acs-workflow.lt_caseobject_namenoquot#</property>
<property name="context">@context;noquote@</property>

<blockquote>
  <include src="case-deadlines-table" case_id="@case.case_id;noquote@" return_url="@return_url;noquote@">
</blockquote>

<table width="60%" border="0" cellpadding="4">
  <form method="get" action="case">
    @done_export_vars@
    <tr bgcolor="#dddddd">
      <td align="right">
	<input type="submit" value="Done" />
      </td>
    </tr>
  </form>
</table>

</master>



