<master src="@portlet_layout@">
<property name="portlet_title"><a href="@relations_url@">#intranet-contacts.Relationships#</a></property>


<table width="100%">
<tr>
  <td colspan="2" class="fill-list-bottom">
    <table border="0" cellpadding="1" cellspacing="1" width="100%">
      <tr>
        <td>

	<include src="/packages/intranet-contacts/lib/contact-relationships" party_id="@party_id@" sort_by_date_p="@sort_by_date_p@"/>

        </td>
      </tr>
    </table>
  </td>
</tr>
</table>