<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-freelance/www/index-postgresql.xql -->
<!-- @author  (frank.bergmann@project-open.com) -->
<!-- @creation-date 2004-09-20 -->
<!-- @arch-tag 285cbeaa-21d3-416f-917c-bb365abc91f1 -->
<!-- @cvs-id $Id$ -->

<queryset>
  
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>
  
  <fullquery name="error_list">
    <querytext>
      
select
        cat.category_id,
        cat.category as quality_category,
        re.minor_errors,
        re.major_errors,
        re.critical_errors
from
        im_categories cat
	LEFT OUTER JOIN
        (select re.*
         from   im_trans_quality_entries re
         where  re.report_id = :report_id
        ) re ON (cat.category_id = re.quality_category_id)
where
        category_type = 'Intranet Translation Quality Type'
order by
        category_id
    
    </querytext>
  </fullquery>
</queryset>
