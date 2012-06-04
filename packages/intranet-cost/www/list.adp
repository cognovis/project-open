<master>
<property name="title">@page_title;noquote@</property>
<property name="main_navbar_label">finance</property>
<property name="sub_navbar">@sub_navbar;noquote@</property>
<property name="left_navbar">@left_navbar_html;noquote@</property>

<form action="/intranet-cost/costs/cost-action" method="POST">
<%= [export_form_vars company_id cost_id return_url]%>
<table width=100% cellpadding=2 cellspacing=2 border=0>
            @table_header_html;noquote@
            @table_body_html;noquote@
            @table_continuation_html;noquote@
            @button_html;noquote@
</table>
</form>
