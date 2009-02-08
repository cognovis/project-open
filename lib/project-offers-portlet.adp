<master src="@portlet_layout@">
<property name="portlet_title">#intranet-contacts.Projects#</property>


<table width="100%">
<tr>
  <td colspan="2" class="fill-list-bottom">
    <table border="0" cellpadding="1" cellspacing="1" width="100%">
      <tr>
        <td>
	    <include src="/packages/invoices/lib/offer-list"
                organization_id="@organization_id@"
                elements="@elements@"
                package_id="@package_id@"
                base_url="@base_url@"
		status_id="1" 
		actions="@actions@"/>
        </td>
      </tr>
    </table>
  </td>
</tr>
</table>