<master src="@portlet_layout@">
<property name="portlet_title">#intranet-contacts.Freelancers#</property>


<table width="100%">
<tr>
  <td colspan="2" class="fill-list-bottom">
    <table border="0" cellpadding="1" cellspacing="1" width="100%">
      <tr>
        <td>
           <include src="/packages/project-manager/lib/customer-group-list"
               customer_id="@customer_id@"
               group_name="@group_name@"
               elements="@elements@"
               cgl_orderby=@cgl_orderby;noquote@
               page=@page@ />
        </td>
      </tr>
    </table>
  </td>
</tr>
</table>