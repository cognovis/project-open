<master src="../../intranet-core/www/master">
<property name="title">@page_title;noquote@</property>
<property name="main_navbar_label">#intranet-trans-quality.Trans_Quality#</property>

<br>

<form action=/intranet-cost/costs/cost-action method=POST>
<%= [export_form_vars company_id cost_id return_url]%>

@component;noquote@

</form>
