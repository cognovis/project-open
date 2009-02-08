<master src="@portlet_layout@">
<property name="portlet_title">#intranet-contacts.Projects#</property>


<table width="100%">
<tr>
  <td colspan="2" class="fill-list-bottom">
    <table border="0" cellpadding="1" cellspacing="1" width="100%">
      <tr>
        <td>
	  <include src="/packages/project-manager/lib/projects" 
		orderby="@orderby;noquote@"
		elements="@elements@"
		package_id="@package_id@"
		actions_p="@actions_p@" 
		bulk_p="@bulk_p@"
		assignee_id="@assignee_id@"
		filter_p="@filter_p@"
		base_url="@base_url@" 
		customer_id="@customer_id@" 
		status_id="@status_id@" 
		current_package_f="@package_id@"
		fmt="@fmt@">
        </td>
      </tr>
    </table>
  </td>
</tr>
</table>