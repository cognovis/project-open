<master src="@portlet_layout@">
<property name="portlet_title">#intranet-contacts.Glossars#</property>


<table width="100%">
<tr>
  <td colspan="2" class="fill-list-bottom">
    <table border="0" cellpadding="1" cellspacing="1" width="100%">
      <tr>
        <td>
	   <include src="/packages/glossar/lib/glossar-list"
                owner_id=@owner_id@
                orderby=@orderby@
                customer_id=@customer_id@
                format=@format@ />
        </td>
      </tr>
    </table>
  </td>
</tr>
</table>