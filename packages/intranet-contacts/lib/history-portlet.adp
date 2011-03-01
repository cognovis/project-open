<master src="@portlet_layout@">
<property name="portlet_title"><a href="@history_url;noquote@">#intranet-contacts.History#</a></property>

<table width="100%">
<tr>
  <td colspan="2" class="fill-list-bottom">
    <table border="0" cellpadding="1" cellspacing="1" width="100%">
      <tr>
        <td>
	    <include
      		src="/packages/intranet-contacts/lib/history"
      		party_id="@party_id@"
      		limit="3"
      		truncate_len="100"
      		size="small"
      		recent_on_top_p="1">
        </td>
      </tr>
    </table>
  </td>
</tr>
</table>