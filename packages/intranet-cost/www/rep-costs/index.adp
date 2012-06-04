<master src="../../../intranet-core/www/master">
<property name="title">#intranet-cost.Absences#</property>
<property name="context">#intranet-cost.context#</property>
<property name="main_navbar_label">finance</property>

<br>
<%= [im_costs_navbar "none" "/intranet/invoices/index" "" "" [list] "costs_rep"] %>

<table width=100% cellpadding=2 cellspacing=2 border=0>
  <%= $table_header_html %>
  <%= $table_body_html %>
  <%= $table_continuation_html %>
</table>

