<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-freelance/www/index-postgresql.xql -->
<!-- @author  (juanjoruizx@yahoo.es) -->
<!-- @creation-date 2004-09-20 -->
<!-- @arch-tag 285cbeaa-21d3-416f-917c-bb365abc91f1 -->
<!-- @cvs-id $Id$ -->

<queryset>
  
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>
  
  <fullquery name="projects_info_query">
    <querytext>
      
select
	u.user_id,
	u.username,
	u.screen_name,
	u.last_visit,
	u.second_to_last_visit,
	u.n_sessions,
	o.creation_date,
	im_email_from_user_id(u.user_id) as email,
	im_name_from_user_id(u.user_id) as name,
	p.first_names,
	p.last_name,
	c.msn_screen_name as msn_email, 
	c.home_phone, 
	c.work_phone, 
	c.cell_phone,
	c.pager,
	c.fax,
	c.aim_screen_name,
	c.msn_screen_name,
	c.icq_number,
	c.ha_line1,
	c.ha_line2,
	c.ha_city,
	c.ha_state,
	c.ha_postal_code,
	c.ha_country_code,
	c.wa_line1,
	c.wa_line2,
	c.wa_city,
	c.wa_state,
	c.wa_postal_code,
	c.wa_country_code,
	c.note,
	c.current_information
	$extra_select
from 
	registered_users u
      LEFT JOIN
	users_contact c USING (user_id),
	persons p,
	acs_objects o
	$extra_from
where 
	u.user_id=p.person_id
	and u.user_id = o.object_id
	$extra_where
$extra_order_by
    
    </querytext>
  </fullquery>
</queryset>
