<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-freelance/www/freelance-info-update-postgresql.xql -->
<!-- @author  (juanjoruizx@yahoo.es) -->
<!-- @creation-date 2004-09-20 -->
<!-- @arch-tag d47e75f6-eab2-4497-9790-3acab936e935 -->
<!-- @cvs-id $Id$ -->

<queryset>
  
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>
  
  
  <fullquery name="freelancers_info">
    <querytext>

select
    im_name_from_user_id(pe.person_id) as user_name,
    f.*
from
    persons pe
      LEFT JOIN
    im_freelancers f ON pe.person_id = f.user_id
where
    pe.person_id = :user_id


    </querytext>
  </fullquery>

</queryset>
