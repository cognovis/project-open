<master src="@portlet_layout@">
<property name="portlet_title"><a href="@attributes_url@">#intranet-contacts.Attributes#</a></property>


<table width="100%">
<tr>
  <td colspan="2" class="fill-list-bottom">
    <table border="0" cellpadding="1" cellspacing="1" width="100%">
      <tr>
        <td>

	<include src="/packages/intranet-contacts/lib/contact-attributes" party_id="@party_id@" />

        </td>
      </tr>
    </table>
  </td>
</tr>
</table>