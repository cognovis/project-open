<master src="@portlet_layout@">
<property name="portlet_title">#intranet-contacts.Projects_tasks#</property>


<table width="100%">
<tr>
  <td colspan="2" class="fill-list-bottom">
    <table border="0" cellpadding="1" cellspacing="1" width="100%">
      <tr>
        <td>
	    <include src="/packages/project-manager/lib/tasks"
                display_mode="@display_mode@"
                elements="@elements@"
                is_observer_p="@is_observer_p@"
                orderby="@orderby;noquote@"
                status_id="@status_id@"
                party_id=@party_id@
                assign_group_p="@assign_group_p@" />
        </td>
      </tr>
    </table>
  </td>
</tr>
</table>