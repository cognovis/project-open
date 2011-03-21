<master src="@portlet_layout@">
<property name="portlet_title">#intranet-contacts.Complaints#</property>

<table width="100%">
<tr>
  <td colspan="2" class="fill-list-bottom">
    <table border="0" cellpadding="1" cellspacing="1" width="100%">
      <tr>
        <td>
	<if @customer_id@ ne "">
           <include src="/packages/intranet-contacts/lib/contact-complaint-list"
	       customer_id="@customer_id@"
               elements="@elements@" />
	</if><else>
	<if @supplier_id@ ne "">
           <include src="/packages/intranet-contacts/lib/contact-complaint-list"
	       supplier_id="@supplier_id@"
               elements="@elements@" />
	</if>
	</else>
        </td>
      </tr>
    </table>
  </td>
</tr>
</table>
	<form action="/contacts/add-edit-complaint">
	#intranet-contacts.Add_complaint_to#: @select_menu;noquote@
	     <input type="hidden" name="customer_id" value="@customer_id@">
	     <input type="submit" value="#intranet-contacts.Add_1#">
	</form>




