-- /packages/intranet-freelance/sql/postgres/intranet-freelance-create.sql
--
-- Copyright (c) 2003-2008 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author guillermo.belcic@project-open.com
-- @author frank.bergmann@project-open.com
-- @author juanjoruizx@yahoo.es

-----------------------------------------------------------
-- HR Skills
--
-- Skills are a list of skills a user can have.
-- Skills are grouped in skill type, for example
-- programming languages, ...


-- Create a new profile for users who are not real users...
select im_create_profile ('Skill Profile','skill_profile');


-----------------------------------------------------------
-- Freelancers
--
-- 
create table im_freelancers (
	user_id			integer
				constraint im_freelancers_pk
				primary key 
				constraint im_freelancers_user_fk
				references users,
	translation_rate	numeric(6,2),
	editing_rate		numeric(6,2),
	hourly_rate		numeric(6,2),
	bank_account		text,
	bank			text,
	payment_method_id	integer
				constraint im_freelancers_payment_fk
				references im_categories,
	note			text,
	private_note		text,
	-- Freelance Recruiting
	rec_source		text,
	rec_status_id		integer
				constraint im_freelancers_rec_stat_fk
				references im_categories,
	rec_test_type		text,
	rec_test_result_id	integer
				constraint im_freelancers_rec_test_fk
				references im_categories
);



-----------------------------------------------------------
-- Freelance Skills
--
-- We want to say something like: This user claims he is excellent
-- at translating into Spanish, but we haven't checked it yet.
-- So what we do is define a mapping between user_ids and
-- skill_ids. Plus we need to reuse categories such as "Languages"
-- so that we need a "skill type".
-- So we define a "skill type", for example "target languages",
-- or "operating systems". And we define individual skills such
-- as "Castillian Spanish" or "Linux 2.4.x".
--

create table im_freelance_skills (
	user_id			integer not null
				constraint im_fl_skills_user_fk
				references users,
	skill_id		integer not null
				constraint im_fl_skills_skill_fk
				references im_categories,
	skill_type_id		integer not null
				constraint im_fl_skills_skill_type_fk
				references im_categories,
	claimed_experience_id   integer
				constraint im_fl_skills_claimed_fk
				references im_categories,
	confirmed_experience_id integer
				constraint im_fl_skills_conf_fk
				references im_categories,
	confirmation_user_id    integer
				constraint im_fl_skills_conf_user_fk
				references users,
	confirmation_date       date,
	-- "map" type of table
	constraint im_fl_skills_pk
	primary key (user_id, skill_id, skill_type_id)
);

create index im_freelance_skills_user_idx on im_freelance_skills(user_id);
create index im_freelance_skills_skill_idx on im_freelance_skills(skill_type_id, skill_id);


create or replace view im_freelance_skill_types as
select category_id as skill_type_id, category as skill_type
from im_categories
where category_type = 'Intranet Skill Type';



-----------------------------------------------------------
-- Skills Associated with other Objects
--
-- We want to say: For this RFQ you need to translate 
-- from English into Spanish (required condition) and be 
-- preferably specialized in "Legal" or "Business".

create sequence im_freelance_object_skill_seq;

create table im_object_freelance_skill_map (
	object_skill_map_id	integer
				constraint im_o_skills_pk
				primary key,
	object_id		integer not null 
				constraint im_o_skills_user_fk
				references acs_objects,
	skill_id		integer not null 
				constraint im_o_skills_skill_fk
				references im_categories,
	skill_type_id		integer not null 
				constraint im_o_skills_skill_type_fk
				references im_categories,

	-- For objects that require skills:
	skill_weight		integer
				constraint im_o_skills_claimed_ck
				check (skill_weight > 0 and skill_weight <= 100),
	skill_required_p	char(1) default('f')
				constraint im_o_skills_required_p
				check (skill_required_p in ('t','f')),

	-- For objects with these skills:
	required_experience_id	integer
				constraint im_o_skills_skill_exp_fk
				references im_categories,
	claimed_experience_id	integer
				constraint im_fl_skills_claimed_fk
				references im_categories,
	confirmed_experience_id	integer
				constraint im_fl_skills_conf_fk
				references im_categories
);

-- Avoid duplicate entries
create unique index im_object_freelance_skill_map_un_idx 
on im_object_freelance_skill_map(object_id, skill_type_id, skill_id);

-- Frequent queries per object expected...
create index im_freelance_object_skillsmap_idx 
on im_object_freelance_skill_map(object_id);


create or replace view im_freelance_skill_types as 
select category_id as skill_type_id, category as skill_type
from im_categories 
where category_type = 'Intranet Skill Type';


-----------------------------------------------------------
-- Menu Modifications
--
-- Let's redirect the "Users" / "Freelancers" menu
-- to the local "index.tcl" page.
update im_menus
set url='/intranet-freelance/index'
where label='users_freelancers';


------------------------------------------------------
-- Freelance Manager Permissions
--

select im_create_profile ('Freelance Managers','profile');


-----------------------------------------------------------
-- We need to define this function as a type of "join(..., ", ") to
-- get the list of skills for each user and skill type.
--
-- select im_freelance_skill_list(26,2000) from dual; -> 'es es_LA'
--
create or replace function im_freelance_skill_list (integer, integer)
returns varchar as '
declare
	p_user_id			alias for $1;
	p_skill_type_id			alias for $2; 

	v_skills			varchar;
	c_user_skills			RECORD;
BEGIN
	v_skills := '''';

	FOR c_user_skills IN	
		select	c.category
		from	im_freelance_skills s,
			im_categories c
		where	s.user_id=p_user_id
			and s.skill_type_id=p_skill_type_id
			and s.skill_id=c.category_id
		order by c.category 
	LOOP
		v_skills := v_skills || '' '' || c_user_skills.category;
	END LOOP;
	RETURN v_skills;
end;' language 'plpgsql';


-- Returns all skills for a person in one TCL string representing an array
create or replace function im_freelance_skill_id_list (integer)
returns varchar as $body$
declare
	p_user_id			alias for $1;
	v_skills			varchar;
	row				RECORD;
BEGIN
	v_skills := '';

	FOR row IN	
		select	s.*
		from	im_freelance_skills s
		where	s.user_id = p_user_id
		order by s.skill_type_id, s.skill_id
	LOOP
		IF '' != v_skills THEN v_skills := v_skills || ' '; END IF;
		v_skills := v_skills || '{' || 
			row.skill_type_id || ' ' || 
			row.skill_id || ' ' || 
			row.confirmed_experience_id || 
			'}';
	END LOOP;
	RETURN v_skills;
end;$body$ language 'plpgsql';



-- Show the freelance information in users view page
--
select im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Users Freelance Component',	-- plugin_name
	'intranet-freelance',		-- package_name
	'left',				-- location
	'/intranet/users/view',		-- page_url
	null,				-- view_name
	90,				-- sort_order
	'im_freelance_info_component $current_user_id $user_id $return_url [im_opt_val freelance_view_name]'
);


-- Show the freelance skills in users view page
--
select im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'User Skills',			-- plugin_name
	'intranet-freelance',		-- package_name
	'right',			-- location
	'/intranet/users/view',		-- page_url
	null,				-- view_name
	190,				-- sort_order
	'im_freelance_object_skill_component -object_id $user_id -return_url $return_url'
);


-- Show the freelance skills in users view page
--
select im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Project Skills',		-- plugin_name
	'intranet-freelance',		-- package_name
	'right',			-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	190,				-- sort_order
	'im_object_skill_component -object_id $project_id -return_url $return_url'
);


-- Show the freelance skills in users view page
--
select im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Users Skills Component',	-- plugin_name
	'intranet-freelance',		-- package_name
	'bottom',			-- location
	'/intranet/users/view',		-- page_url
	null,				-- view_name
	80,				-- sort_order
	'im_freelance_skill_component $current_user_id $user_id $return_url'
);


-- Show the freelance skills in users view page
--
select im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Users Skills Component',	-- plugin_name
	'intranet-freelance',		-- package_name
	'bottom',			-- location
	'/intranet/users/view',		-- page_url
	null,				-- view_name
	80,				-- sort_order
	'im_freelance_skill_component $current_user_id $user_id $return_url'
);


-- Show the freelance list in member-add page
--
select im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'freelance list Component',	-- plugin_name
	'intranet-freelance',		-- package_name
	'bottom',			-- location
	'/intranet/member-add',		-- page_url
	null,				-- view_name
	10,				-- sort_order
	'im_freelance_member_select_component $object_id $return_url'
);



-- Show the freelance list in member-add page
--
select im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Freelance Gantt Resource Select Component',	-- plugin_name
	'intranet-freelance',		-- package_name
	'bottom',			-- location
	'/intranet/member-add',		-- page_url
	null,				-- view_name
	20,				-- sort_order
	'im_freelance_gantt_resource_select_component -object_id $object_id -return_url $return_url'
);




-- -----------------------------------------------------
-- Add privileges for freelance_skills and freelance_skillconfs
--


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select	count(*) into v_count from acs_privileges
	where	privilege = ''add_freelance_skills'';
	IF v_count > 0 THEN return 0; END IF;

	PERFORM acs_privilege__create_privilege(''add_freelance_skills'',''Add Freelance Skills'',''Add Freelance Skills'');
	PERFORM acs_privilege__add_child(''admin'', ''add_freelance_skills'');
	
	PERFORM acs_privilege__create_privilege(''view_freelance_skills'',''View Freelance Skills'',''View Freelance Skills'');
	PERFORM acs_privilege__add_child(''admin'', ''view_freelance_skills'');
	
	PERFORM im_priv_create(''view_freelance_skills'',''Accounting'');
	PERFORM im_priv_create(''view_freelance_skills'',''P/O Admins'');
	PERFORM im_priv_create(''view_freelance_skills'',''Project Managers'');
	PERFORM im_priv_create(''view_freelance_skills'',''Senior Managers'');
	PERFORM im_priv_create(''view_freelance_skills'',''Freelance Managers'');
	PERFORM im_priv_create(''view_freelance_skills'',''Employees'');
	
	PERFORM im_priv_create(''add_freelance_skills'',''Accounting'');
	PERFORM im_priv_create(''add_freelance_skills'',''P/O Admins'');
	PERFORM im_priv_create(''add_freelance_skills'',''Senior Managers'');
	PERFORM im_priv_create(''add_freelance_skills'',''Project Managers'');
	PERFORM im_priv_create(''add_freelance_skills'',''Freelance Managers'');
	
	PERFORM im_priv_create(''view_freelance_skills'',''Freelancers'');
	PERFORM im_priv_create(''add_freelance_skills'',''Freelancers'');

	PERFORM acs_privilege__create_privilege(''add_freelance_skillconfs'',''Add Freelance Skillconfs'',''Add Freelance Skillconfs'');
	PERFORM acs_privilege__add_child(''admin'', ''add_freelance_skillconfs'');
	
	PERFORM acs_privilege__create_privilege(''view_freelance_skillconfs'',''View Freelance Skillconfs'',''View Freelance Skillconfs'');
	PERFORM acs_privilege__add_child(''admin'', ''view_freelance_skillconfs'');
	
	PERFORM im_priv_create(''view_freelance_skillconfs'',''Accounting'');
	PERFORM im_priv_create(''view_freelance_skillconfs'',''P/O Admins'');
	PERFORM im_priv_create(''view_freelance_skillconfs'',''Project Managers'');
	PERFORM im_priv_create(''view_freelance_skillconfs'',''Senior Managers'');
	PERFORM im_priv_create(''view_freelance_skillconfs'',''Freelance Managers'');
	PERFORM im_priv_create(''view_freelance_skillconfs'',''Employees'');
	
	PERFORM im_priv_create(''add_freelance_skillconfs'',''Accounting'');
	PERFORM im_priv_create(''add_freelance_skillconfs'',''P/O Admins'');
	PERFORM im_priv_create(''add_freelance_skillconfs'',''Senior Managers'');
	PERFORM im_priv_create(''add_freelance_skillconfs'',''Project Managers'');
	PERFORM im_priv_create(''add_freelance_skillconfs'',''Freelance Managers'');

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-- \i intranet-freelance-score.sql
\i ../common/intranet-freelance-common.sql
\i ../common/intranet-freelance-backup.sql



-- Create freelance report
SELECT im_report_new (
	'Freelance Skills',		-- report_name
	'reporting-freelance-skills',	-- report_code
	'intranet-freelance',		-- package_key
	100,				-- report_sort_order
	(select menu_id from im_menus where label = 'reporting-other'),	-- parent_menu_id
	'
	select	''<a href=/intranet/users/view?user_id='' || user_id || ''>'' ||
		im_name_from_user_id(s.user_id) || ''</a>'' as user_name,
		im_category_from_id(s.skill_type_id) as skill_type,
		im_category_from_id(s.skill_id) as skill,
		im_category_from_id(s.confirmed_experience_id) as level
	from	im_freelance_skills s,
		persons p
	where	p.person_id = s.user_id
	order by
		last_name, first_names, skill_type, skill
	'
);

