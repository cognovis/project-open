<master>
<property name="title">@page_title@</property>
<property name="main_navbar_label"></property>

<%= [im_box_header $page_title] %>

<form action='@return_url;noquote@' method=GET>
<%= [export_form_vars return_url object_type] %>

<table cellspacing=2 cellpadding=2>
@object_select_html;noquote@
<tr>
	<td colspan=2><input type=submit value="@submit_msg@"></td>
</tr>
</table>
</form>
<%= [im_box_footer] %>

