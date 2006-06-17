<!-- packages/intranet-trans-invoices/www/invoices/new.adp -->
<!-- @author Juanjo Ruiz (juanjoruizx@yahoo.es) -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="../../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">finance</property>

@filter_html;noquote@

@cost_navbar;noquote@

<form method=POST action='new-2'>
<%= [export_form_vars target_cost_type_id] %>
  <table width=100% cellpadding=2 cellspacing=2 border=0>
    @table_header_html;noquote@
    @table_body_html;noquote@
    @table_continuation_html;noquote@
    @submit_button;noquote@
  </table>
</form>

