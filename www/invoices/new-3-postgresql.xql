<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-trans-invoices/www/invoices/new-3-postgresql.xql -->
<!-- @author  (juanjoruizx@yahoo.es) -->
<!-- @creation-date 2004-09-21 -->
<!-- @arch-tag da6a197a-0c04-46a3-83dd-b30e172b9881 -->
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
	c.company_name,
	c.company_path,
	c.company_path as company_short_name,
        cc.country_name
from
	im_companies c
      LEFT JOIN
        im_offices o ON c.main_office_id=o.office_id
      LEFT JOIN
        country_codes cc ON o.address_country_code=cc.iso
where 
        c.company_id = :company_id

    </querytext>
  </fullquery>


  <fullquery name="task_sum">
    <querytext>

select
	s.task_sum,
	s.task_type_id,
	s.subject_area_id,
	s.source_language_id,
	s.target_language_id,
	s.task_uom_id,
	c_type.category as task_type,
	c_uom.category as task_uom,
	c_target.category as target_language,
	s.company_id,
	s.project_id,
	p.project_name,
	p.project_path,
	p.project_path as project_short_name,
	p.company_project_nr
from
	($task_sum_inner_sql) s
      LEFT JOIN
	im_categories c_uom ON s.task_uom_id=c_uom.category_id
      LEFT JOIN
	im_categories c_type ON s.task_type_id=c_type.category_id
      LEFT JOIN
	im_categories c_target ON s.target_language_id=c_target.category_id
      LEFT JOIN
	im_projects p ON s.project_id=p.project_id
order by
	p.project_id

    </querytext>
  </fullquery>

</queryset>
