<master src="@portlet_layout@">
<property name="portlet_title">#intranet-contacts.MailTracking#</property>

<table width="100%">
<tr>
  <td colspan="2" class="fill-list-bottom">
    <table border="0" cellpadding="1" cellspacing="1" width="100%">
      <tr>
        <td>
	    <include
      		src="/packages/mail-tracking/lib/messages"
      		party="@party_id@"
		page="@page@"
		page_size="@page_size@"
		show_filter_p="f"
		elements="@elements@">
        </td>
      </tr>
    </table>
  </td>
</tr>
</table>