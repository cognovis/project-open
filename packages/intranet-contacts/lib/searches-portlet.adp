<master src="@portlet_layout@">
<property name="portlet_title">#intranet-contacts.In_Searches#</property>


<table width="100%">
<tr>
  <td colspan="2" class="fill-list-bottom">
    <table border="0" cellpadding="1" cellspacing="1" width="100%">
      <tr>
        <td>
	 <include
	      src="/packages/intranet-contacts/lib/searches"
	      party_id="@party_id@"
	      hide_form_p="t" />
        </td>
      </tr>
    </table>
  </td>
</tr>
</table>