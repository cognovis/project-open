<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-timesheet2-invoices/tcl/intranet-timesheet2-invoices-procs-postgresql.xql -->
<!-- @author  (frank.bergmann@project-open.com) -->
<!-- @creation-date 2004-09-21 -->
<!-- @arch-tag ebd131d9-8c90-4c9b-a02c-8058aac72256 -->
<!-- @cvs-id $Id$ -->

<queryset>
  
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>
  
  <fullquery name="im_timesheet_price_component.prices">
    <querytext>

select
	p.*,
	c.company_path as company_short_name,
	im_category_from_id(uom_id) as uom,
	im_category_from_id(task_type_id) as task_type,
	im_material_nr_from_id(material_id) as material
from
	im_timesheet_prices p
      LEFT JOIN
	im_companies c USING (company_id)
where 
	p.company_id=:company_id
order by
	currency,
	uom_id,
	task_type_id desc


    </querytext>
  </fullquery>

</queryset>
