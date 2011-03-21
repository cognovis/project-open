<master src="@portlet_layout@">
<property name="portlet_title">#intranet-contacts.Working_project_tasks#</property>


<table width="100%">
<tr>
  <td colspan="2" class="fill-list-bottom">
    <table border="0" cellpadding="1" cellspacing="1" width="100%">
      <tr>
        <td>
	    <include src="/packages/project-manager/lib/tasks"
                filter_party_id="@from_party_id@"
		page="@page@"
		page_size="@page_size@"
		orderby_p="@orderby_p@"
		display_mode="list"
		pt_orderby="@pt_orderby@"
		status_id="@status_id@"
		elements="@elements@"
	    />
        </td>
      </tr>
    </table>
  </td>
</tr>
</table>