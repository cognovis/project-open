<master>
<property name="title">@page_title@</property>
<property name="context">#intranet-core.context#</property>
<property name="main_navbar_label">events</property>
<property name="sub_navbar">@event_navbar_html;noquote@</property>
<property name="left_navbar">@left_navbar_html;noquote@</property>

<table cellspacing=0 cellpadding=0 border=0 width="100%">
<form action=/intranet-events/action method=POST>
<%= [export_form_vars return_url] %>
<tr valign=top>
<td>

	<table class="table_list_page">
	<%= $table_header_html %>
	<%= $table_body_html %>
	<%= $table_continuation_html %>
	<%= $table_submit_html %>
	</table>

</td>
<td width="<%= $dashboard_column_width %>">
<%= $dashboard_column_html %>
</td>
</tr>
</form>
</table>

