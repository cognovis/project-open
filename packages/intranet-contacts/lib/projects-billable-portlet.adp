<master src="@portlet_layout@">
<property name="portlet_title"><a href="/invoices/projects-billable?organization_id=@organization_id@"">#invoices.Billable_Projects#</a></property>

<table width="100%">
<tr>
  <td colspan="2" class="fill-list-bottom">
    <table border="0" cellpadding="1" cellspacing="1" width="100%">
      <tr>
        <td>
	  <include src="/packages/invoices/lib/projects-billable"
                organization_id="@organization_id@"
                elements="@elements@"
                package_id="@package_id@"
                base_url="@base_url@"
		no_actions_p="1" />
        </td>
      </tr>
    </table>
  </td>
</tr>
</table>