<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-invoices/www/new-oracle.xql -->
<!-- @author  (nsadmin@barna.competitiveness.com) -->
<!-- @creation-date 2004-09-22 -->
<!-- @arch-tag 299ad547-08a7-43b1-aee0-6d341f9727f7 -->
<!-- @cvs-id $Id: new-oracle.xql,v 1.2 2004/09/29 14:31:28 cvs Exp $ -->

<queryset>
  
  
  <rdbms>
    <type>oracle</type>
    <version>8.1.6</version>
  </rdbms>
  
  <fullquery name="invoices_info_query">
    <querytext>
      select
	i.invoice_nr,
	ci.customer_id,
	ci.provider_id,
	ci.effective_date,
	ci.payment_days,
	ci.vat,
	ci.tax,
	ci.note as cost_note,
	i.payment_method_id,
	ci.template_id,
	ci.cost_status_id,
	ci.cost_type_id,
	im_category_from_id(ci.cost_type_id) as cost_type,
	im_name_from_user_id(i.company_contact_id) as company_contact_name,
	im_email_from_user_id(i.company_contact_id) as company_contact_email,
	c.company_name as company_name,
	c.company_path as company_short_name,
	p.company_name as provider_name,
	p.company_path as provider_short_name
      from
	im_invoices i, 
	im_costs ci,
	im_companies c,
	im_companies p
      where 
        i.invoice_id=:invoice_id
	and ci.customer_id = c.company_id(+)
	and ci.provider_id = p.company_id(+)
	and i.invoice_id = ci.cost_id
    </querytext>
  </fullquery>
  <fullquery name="invoice_item">
    <querytext>
      select
	i.*,
	p.*,
	p.project_nr as project_short_name,
	im_category_from_id(i.item_uom_id) as item_uom,
	im_category_from_id(i.item_type_id) as item_type
      from
	im_invoice_items i,
	im_projects p
      where
	i.invoice_id = :invoice_id
	and i.project_id=p.project_id(+)
      order by
	i.project_id
    </querytext>
  </fullquery>
</queryset>
