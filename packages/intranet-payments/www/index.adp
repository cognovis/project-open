<master src="master">
<property name="title">@page_title@</property>
<property name="main_navbar_label">finance</property>

<%= [im_costs_navbar $letter "/intranet-payments/index" $next_page_url $previous_page_url [list status_id type_id start_idx order_by how_many view_name letter] "payments_list"] %>

<form action=payment-action method=POST>
<%= [export_form_vars company_id payment_id return_url] %>

<table width=100% cellpadding=2 cellspacing=2 border=0>
    @table_header_html;noquote@
    @table_body_html;noquote@
    @table_continuation_html;noquote@
<tr>
  <td colspan=$colspan align=right>
    <input type=submit name=del value='#intranet-payments.Del#'>
  </td>
</tr>

  </table>
</form>