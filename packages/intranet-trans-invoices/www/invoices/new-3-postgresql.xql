<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-trans-invoices/www/invoices/new-3-postgresql.xql -->
<!-- @author  (juanjoruizx@yahoo.es) -->
<!-- @creation-date 2004-09-21 -->
<!-- @arch-tag da6a197a-0c04-46a3-83dd-b30e172b9881 -->
<!-- @cvs-id $Id: new-3-postgresql.xql,v 1.3 2006/04/07 23:07:41 cvs Exp $ -->

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


</queryset>
