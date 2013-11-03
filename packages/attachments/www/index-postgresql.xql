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
  <fullquery name="users_select">
    <querytext>

select
	u.user_id, u.username, u.screen_name, u.last_visit, u.second_to_last_visit,
	u.n_sessions, im_name_from_user_id(u.user_id) as name,
	pa.email, 
	pe.first_names, pe.last_name,
	c.msn_screen_name as msn_email, 
	c.home_phone, c.work_phone, c.cell_phone, c.pager,
	c.fax, c.aim_screen_name, c.msn_screen_name, c.icq_number,
	c.ha_line1, c.ha_line2, c.ha_city, c.ha_state, c.ha_postal_code, c.ha_country_code,
	c.wa_line1, c.wa_line2, c.wa_city, c.wa_state, c.wa_postal_code, c.wa_country_code,
	c.note, c.current_information,
	f.bank_account, f.bank, f.payment_method_id, f.rec_source, 
	f.rec_status_id, f.rec_test_type, f.rec_test_result_id
	$extra_select
from 
	persons pe,
	parties pa,
	(	SELECT	m.member_id,
			mr.member_state
		FROM	group_member_map m, 
			membership_rels mr
		WHERE	m.group_id = acs__magic_object_id('registered_users') AND 
			m.rel_id = mr.rel_id AND 
			m.container_id = m.group_id AND 
			m.rel_type = 'membership_rel' AND
			mr.member_state = 'approved'
	) reg_mem,
	users u
	LEFT OUTER JOIN users_contact c on (u.user_id = c.user_id)
	LEFT OUTER JOIN im_freelancers f on (u.user_id = f.user_id)
	$extra_from
where 
	u.user_id = pe.person_id and
	u.user_id = pa.party_id and
	u.user_id = reg_mem.member_id
	$extra_where
$extra_order_by

    </querytext>
  </fullquery>


  <fullquery name="users_select_old">
    <querytext>
      
select
	u.user_id,
	u.username,
	u.screen_name,
	u.last_visit,
	u.second_to_last_visit,
	u.n_sessions,
	u.creation_date,
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
	f.rec_status_id, f.rec_test_type, f.rec_test_result_id
from 
	persons p,
	cc_users u
	LEFT OUTER JOIN users_contact c on (u.user_id = c.user_id)
	LEFT OUTER JOIN im_freelancers f on (u.user_id = f.user_id)
where 
	u.user_id = p.person_id
	and u.member_state = 'approved'

    </querytext>
  </fullquery>

</queryset>
