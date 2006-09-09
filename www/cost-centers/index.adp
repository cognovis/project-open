<master src="../../../intranet-core/www/master">
<property name="title">@page_title;noquote@</property>
<property name="main_navbar_label">finance</property>


<form action=cost-center-action method=post>
<%= [export_form_vars return_url] %>

<table width="100%">
@table_header;noquote@
@table;noquote@
</table>

</form>

