<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-timesheet2-invoices/www/invoices/index-postgresql.xql -->
<!-- @author  (nsadmin@barna.competitiveness.com) -->
<!-- @creation-date 2004-09-21 -->
<!-- @arch-tag df8e9b42-1ce7-4989-8d65-efe8dc6f99cb -->
<!-- @cvs-id $Id$ -->
<!-- ToDo: Implement pagination -->

<queryset>
  
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>


  <fullquery name="invoices_info_query">
    <querytext>

select
        i.*,
        (to_date(to_char(i.invoice_date,'YYYY-MM-DD'),'YYYY-MM-DD') + i.payment_days) as due_date_calculated,
	ii.invoice_amount,
	to_char(ii.invoice_amount,:cur_format) as invoice_amount_formatted,
	ii.invoice_currency,
	pa.payment_amount,
	pa.payment_currency,
        u.email as company_contact_email,
        u.first_names||' '||u.last_name as company_contact_name,
        c.group_name as company_name,
        c.short_name as company_short_name,
        im_category_from_id(i.cost_status_id) as cost_status,
        sysdate - (to_date(to_char(i.invoice_date, 'YYYY-MM-DD'),'YYYY-MM-DD') + i.payment_days) as overdue
from
        im_invoices_active i
      LEFT JOIN
        users u ON i.company_contact_id=u.user_id
      LEFT JOIN
        user_groups c ON i.company_id=c.group_id
      LEFT JOIN
        (select
                invoice_id,
                sum(item_units * price_per_unit) as invoice_amount,
		max(currency) as invoice_currency
         from im_invoice_items
         group by invoice_id
        ) ii USING (invoice_id)
	(select
		sum(amount) as payment_amount, 
		max(currency) as payment_currency,
		invoice_id 
	 from im_payments
	 group by invoice_id
	) pa USING (invoice_id)
where
      1=1
        $where_clause
$order_by_clause

    </querytext>
  </fullquery>
  
</queryset>
