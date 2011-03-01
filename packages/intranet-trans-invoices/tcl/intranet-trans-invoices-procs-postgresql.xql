<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-trans-invoices/tcl/intranet-trans-invoices-procs-postgresql.xql -->
<!-- @author  (juanjoruizx@yahoo.es) -->
<!-- @creation-date 2004-09-21 -->
<!-- @arch-tag ebd131d9-8c90-4c9b-a02c-8058aac72256 -->
<!-- @cvs-id $Id: intranet-trans-invoices-procs-postgresql.xql,v 1.3 2009/03/31 17:16:47 cvs Exp $ -->

<queryset>
  
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>
  
  <fullquery name="im_trans_price_component.prices">
    <querytext>

select
	p.*,
	c.company_path as company_short_name,
	im_category_from_id(uom_id) as uom,
	im_category_from_id(task_type_id) as task_type,
	im_category_from_id(target_language_id) as target_language,
	im_category_from_id(source_language_id) as source_language,
	im_category_from_id(subject_area_id) as subject_area,
	im_category_from_id(file_type_id) as file_type,
	to_char(min_price, :min_price_format) as min_price_formatted
from
	im_trans_prices p
      LEFT JOIN
	im_companies c USING (company_id)
where 
	p.company_id=:company_id
order by
	currency,
	uom_id,
	target_language_id desc,
	task_type_id desc,
	source_language_id desc

    </querytext>
  </fullquery>

</queryset>
