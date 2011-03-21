------------------------------------------------------------
-- Users
------------------------------------------------------------

-- Get everything about a user
select
	u.*,
	$freelance_select
	c.*,
	emp.*,
	pe.*,
	pa.*
from
	users u
	$freelance_pg_join
	LEFT JOIN
		persons pe ON u.user_id = pe.person_id
	LEFT JOIN
		parties pa ON u.user_id = pa.party_id
	LEFT JOIN
		users_contact c USING (user_id)
	LEFT JOIN
		im_employees emp ON u.user_id = emp.employee_id
	LEFT JOIN
		country_codes ha_cc ON c.ha_country_code = ha_cc.iso
	LEFT JOIN
		country_codes wa_cc ON c.wa_country_code = wa_cc.iso
where
	u.user_id = :user_id


-- Get a list of recently registered users
select
	u.user_id,
	u.username,
	u.screen_name,
	u.last_visit,
	u.second_to_last_visit,
	u.n_sessions,
	to_char(u.creation_date, :date_format) as creation_date,
	u.member_state,
	im_email_from_user_id(u.user_id) as email,
	im_name_from_user_id(u.user_id) as name
from
	cc_users u
order by
	u.creation_date DESC
;

-- Get the Profile ("group") memberships of a user
select DISTINCT
	g.group_id,
	g.group_name
from
	acs_objects o,
	groups g,
	group_member_map m,
	membership_rels mr
where
	m.member_id = :user_id
	and m.group_id = g.group_id
	and g.group_id = o.object_id
	and o.object_type = 'im_profile'
	and m.rel_id = mr.rel_id
	and mr.member_state = 'approved'
;


-- Get Employee information.
-- Not all users are employees - obviously.
select
	u.user_id,
	im_name_from_user_id(u.user_id) as employee_name,
	emp.*
from
	registered_users u,
	group_distinct_member_map gm
	LEFT OUTER JOIN
		im_employees_active emp ON (u.user_id = emp.employee_id)
where
	u.user_id = gm.member_id
	and gm.group_id = [im_employee_group_id]
order by 
	lower(im_name_from_user_id(u.user_id))
;


-- Is the :current_user_id allowed to manage :user_id?
--
-- Get the list of profiles of user_id (the one to be managed)
-- together with the information if current_user_id can read/write
-- it. m.group_id are all the groups to whom :user_id belongs.
-- :current_user_id must be able to have view/read/write/admin
-- perms on ALL of these groups.
select
	m.group_id,
	im_object_permission_p(m.group_id, :current_user_id, 'view') as view_p,
	im_object_permission_p(m.group_id, :current_user_id, 'read') as read_p,
	im_object_permission_p(m.group_id, :current_user_id, 'write') as write_p,
	im_object_permission_p(m.group_id, :current_user_id, 'admin') as admin_p
from
	acs_objects o,
	group_distinct_member_map m
where
	m.member_id=:user_id
	and m.group_id = o.object_id
	and o.object_type = 'im_profile'
;



-- Create a new User
select acs_user__new(
	null,		-- user_id
	'user',		-- object_type
	now(),		-- creation_date
	null,		-- creation_user
	null,		-- creation_ip
	null,		-- authority_id
	:username,	-- username
	:email,		-- email
	null,		-- url
	:first_names,	-- first_names
	:last_name,	-- last_name
	:password,	-- password
	:salt,		-- salt
	null,		-- screen_name
	't',
	null		-- context_id
);


-------------------------------------------------------------
-- Users_Contact information
--
-- Table from ACS 3.4 data model copied into the Intranet 
-- in order to facilitate the porting process. However, this
-- information should be incorporated into a im_users table
-- or something similar in the future.

create table users_contact (
	user_id			integer 
				constraint users_contact_pk
				primary key
				constraint users_contact_pk_fk
				references users,
	home_phone		varchar(100),
	priv_home_phone		integer,
	work_phone		varchar(100),
	priv_work_phone 	integer,
	cell_phone		varchar(100),
	priv_cell_phone 	integer,
	pager			varchar(100),
	priv_pager		integer,
	fax			varchar(100),
	priv_fax		integer,
				-- AOL Instant Messenger
	aim_screen_name		varchar(50),
	priv_aim_screen_name	integer,
				-- MSN Instanet Messenger
	msn_screen_name		varchar(50),
	priv_msn_screen_name	integer,
				-- also ICQ
	icq_number		varchar(50),
	priv_icq_number		integer,
				-- Which address should we mail to?
	m_address		char(1) check (m_address in ('w','h')),
				-- home address
	ha_line1		varchar(80),
	ha_line2		varchar(80),
	ha_city			varchar(80),
	ha_state		varchar(80),
	ha_postal_code		varchar(80),
	ha_country_code		char(2) 
				constraint users_contact_ha_cc_fk
				references country_codes(iso),
	priv_ha			integer,
				-- work address
	wa_line1		varchar(80),
	wa_line2		varchar(80),
	wa_city			varchar(80),
	wa_state		varchar(80),
	wa_postal_code		varchar(80),
	wa_country_code		char(2)
				constraint users_contact_wa_cc_fk
				references country_codes(iso),
	priv_wa			integer,
				-- used by the intranet module
	note			varchar(4000),
	current_information	varchar(4000)
);
