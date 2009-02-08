<master src="@portlet_layout@">
<property name="portlet_title"><a href="tasks">#intranet-contacts.Tasks#</a></property>


<table width="100%">
<tr>
  <td colspan="2" class="fill-list-bottom">
    <table border="0" cellpadding="1" cellspacing="1" width="100%">
      <tr>
        <td>
	     <include
        	src="/packages/tasks/lib/tasks"
	        object_id=@object_id@
                package_id="@package_id@"
        	hide_form_p="t" 
		page_size="@page_size@" 
		show_filters_p="@show_filters_p@"
                hide_elements=@hide_elements@ />	
        </td>
      </tr>
    </table>
  </td>
</tr>
</table>
