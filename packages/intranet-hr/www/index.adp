<master src="../../intranet-core/www/master">
<property name="title">Companies</property>
<property name="context">context</property>
<property name="main_navbar_label">user</property>

<%= $filter_html %>
<%= $navbar_html %>
<table width=100% cellpadding=2 cellspacing=2 border=0>
  <%= $table_header_html %>
  <%= $table_body_html %>
  <%= $table_continuation_html %>
</table>
