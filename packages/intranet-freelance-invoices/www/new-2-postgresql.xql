<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-trans-invoices/www/new-2-postgresql.xql -->
<!-- @author Juanjo Ruiz (juanjoruizx@yahoo.es) -->
<!-- @creation-date 2004-10-07 -->
<!-- @arch-tag 7874400c-d95a-4541-a9e9-bf9bb10e8552 -->
<!-- @cvs-id $Id$ -->

<queryset>
  
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>
  
  <fullquery name="invoices_info_query">
    <querytext>
select
        c.*,
        o.*,
        im_email_from_user_id(c.accounting_contact_id) as company_contact_email,
        im_name_from_user_id(c.accounting_contact_id) as  company_contact_name,
        c.company_name as company_name,
        c.company_path as company_path,
        c.company_path as company_short_name,
        cc.country_name
from
        im_companies c
      LEFT JOIN
        im_offices o ON c.main_office_id=o.office_id
      LEFT JOIN
        country_codes cc ON o.address_country_code=cc.iso
where
        c.company_id = :provider_id
    </querytext>
  </fullquery>

  <fullquery name="references_prices">
    <querytext>
select 
	pr.price_id,
	pr.relevancy as price_relevancy,
	to_char(pr.price, :number_format) as price,
	pr.company_id as price_company_id,
	pr.uom_id as uom_id,
	pr.task_type_id as task_type_id,
	pr.target_language_id as target_language_id,
	pr.source_language_id as source_language_id,
	pr.subject_area_id as subject_area_id,
	pr.valid_from,
	pr.valid_through,
	pr.price_note,
	c.company_path as price_company_name,
        im_category_from_id(pr.uom_id) as price_uom,
        im_category_from_id(pr.task_type_id) as price_task_type,
        im_category_from_id(pr.target_language_id) as price_target_language,
        im_category_from_id(pr.source_language_id) as price_source_language,
        im_category_from_id(pr.subject_area_id) as price_subject_area
from
	(
		(select 
			im_trans_prices_calc_relevancy (
				p.company_id, :provider_id,
				p.task_type_id, :task_type_id,
				p.subject_area_id, :subject_area_id,
				p.target_language_id, :target_language_id,
				p.source_language_id, :source_language_id
			) as relevancy,
			p.price_id,
			p.price,
			p.company_id as company_id,
			p.uom_id,
			p.task_type_id,
			p.target_language_id,
			p.source_language_id,
			p.subject_area_id,
			p.valid_from,
			p.valid_through,
			p.note as price_note
		from im_trans_prices p
		where
			uom_id=:task_uom_id
			and currency = :currency
			and p.company_id not in (
				select company_id
				from im_companies
				where company_path = 'internal'
			)

		)
	) pr
      LEFT JOIN
	im_companies c ON pr.company_id = c.company_id
where
        relevancy >= 0
order by
	pr.relevancy desc,
	pr.company_id,
	pr.uom_id

    </querytext>
  </fullquery>
</queryset>
