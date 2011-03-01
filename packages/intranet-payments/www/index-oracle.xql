<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-payments/www/index-oracle.xql -->
<!-- @author  (nsadmin@barna.competitiveness.com) -->
<!-- @creation-date 2004-09-29 -->
<!-- @arch-tag 9114ae31-366e-4bd8-8efd-09f7d36f204d -->
<!-- @cvs-id $Id: index-oracle.xql,v 1.1 2004/09/29 17:02:00 cvs Exp $ -->

<queryset>
  
  
  <rdbms>
    <type>oracle</type>
    <version>8.1.6</version>
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
	acs_object.name(ci.customer_id) as company_name,
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
