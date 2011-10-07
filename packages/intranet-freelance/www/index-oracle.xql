<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-core/www/offices/index-postgresql.xql -->
<!-- @author  (frank.bergmann@project-open.com) -->

<queryset>
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>
  

  <fullquery name="users_select">
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
	c.current_information,
	f.bank_account, f.bank, f.payment_method_id, f.rec_source, 
	f.rec_status_id, f.rec_test_type, f.rec_test_result_id,
	im_category_from_id(f.rec_status_id) as rec_status,
	im_category_from_id(f.rec_test_result_id) as rec_test_result	
	$extra_select
from 
	registered_users u, 
	users_contact c,
	persons p,
	acs_objects o,
	im_freelancers f
	$extra_from
where 
	u.user_id = p.person_id
	and u.user_id = c.user_id(+)
	and u.user_id = o.object_id
	and u.user_id = f.user_id(+)
	$extra_where
$extra_order_by	        
	        
    </querytext>
  </fullquery>

</queryset>
