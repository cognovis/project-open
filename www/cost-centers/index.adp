<master src="../../../intranet-core/www/master">
<property name="title">@page_title;noquote@</property>
<property name="main_navbar_label">finance</property>

<h1>@page_title@</h1>

<table width='90%'>
<tr><td>
<%= [lang::message::lookup "" intranet-cost.Cost_Center_permissions_help "
<h3>Cost Center Permission Help</h3>

'Cost Centers' represent a kind of refined department structure of a company.
This structure is suitable particularmente for larger companies to determine
the access rights for finanancial documents. A department head should be
able to see what's happening in his group. However, he or she should not
necessarily know what's going on in other departments and in the company
as a whole.<p>

The follwoing table shows the Cost Center hierarchy and lists the access 
permissions for each Cost Center and each user role.<p>

Please note that this table 'inherits' from the permissions set in the
'Admin - Profiles' section. You can't remove permissions here that 
you have set there.<p>

<h3>Abbreviations</h3>

In the following, the first line refers to to Read permissions, while the
second line revers to Write permissions:
"] %>
</td></tr>
</table>

<li>R - Read All - User can read all types of financial documents for this Cost Center
<li>W - Read All - User can create/modify all types of financial documents for this Cost Center
<li>I - Customer Invoices
<li>Q - Customer Quotes
<li>D - Delivery Notes
<li>B - Provider Bills
<li>P - Purchase Orders
<li>T - Timesheet Information
<li>E - Expense Reports

<form action=cost-center-action method=post>
<%= [export_form_vars return_url] %>

<table width="100%">
@table_header;noquote@
@table;noquote@
</table>

</form>

