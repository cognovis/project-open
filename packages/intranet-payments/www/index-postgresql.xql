<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-payments/www/index-postgresql.xql -->
<!-- @author  (nsadmin@barna.competitiveness.com) -->
<!-- @creation-date 2004-09-29 -->
<!-- @arch-tag 8e48da87-1063-4620-809d-0881bf506622 -->
<!-- @cvs-id $Id: index-postgresql.xql,v 1.1 2004/09/29 17:02:00 cvs Exp $ -->

<queryset>
  
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>
  
  <fullquery name="payments_info_query">
    <querytext>
      select
        p.*,
	p.amount as payment_amount,
	p.currency as payment_currency,
	ci.customer_id,
	ci.amount as cost_amount,
	ci.currency as cost_currency,
	ci.cost_name,
	acs_object__name(ci.customer_id) as company_name,
        im_category_from_id(p.payment_type_id) as payment_type,
        im_category_from_id(p.payment_status_id) as payment_status
      from
        im_payments p,
	im_costs ci
      where
	p.cost_id = ci.cost_id
        $where_clause
      $order_by_clause
      </querytext>
    </fullquery>
  
</queryset>
