<master src="/packages/intranet-core/www/admin/master">
<property name="title">@page_title;noquote@</property>
<property name="main_navbar_label">finance</property>
<property name="admin_navbar_label">admin_cost_centers</property>

<h1>@page_title@</h1>

<table width='90%'>
<tr><td>
<%= [lang::message::lookup "" intranet-cost.Cost_Center_permissions_help "
<h3>Cost Center Permission Help</h3>

'Cost Centers' represent a kind of refined department structure of a company.
This structure is suitable for larger companies to determine
the access rights for financial documents. A department head should be
able to see what's happening in his group. However, she should not
necessarily know what's going on in other departments and in the company
as a whole.<p>
"] %>
<form action=cost-center-action method=post>
<%= [export_form_vars return_url] %>

<table width="100%">
@table_header;noquote@
@table;noquote@
</table>

</form>

