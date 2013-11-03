-- /packages/intranet-freelance/sql/oracle/intranet-freelance-create.sql
--
-- Copyright (c) 2003-2004 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author guillermo.belcic@project-open.com
-- @author frank.bergmann@project-open.com


-----------------------------------------------------------
-- Freelance Management specific data model
--
-- "Freelancers" are a kind of users, exteded by payment
-- methods and a set of skills/tools/...

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
	translation_rate	number(6,2),
	editing_rate		number(6,2),
	hourly_rate		number(6,2),
	bank_account		varchar(200),
	bank			varchar(100),
	payment_method_id	integer
				constraint im_freelancers_payment_fk
				references im_categories,
	note			varchar(4000),
	private_note		varchar(4000),
        -- Freelance Recruiting
        rec_source              varchar(400),
        rec_status_id           integer
                                constraint im_freelancers_rec_stat_fk
                                references im_categories,
        rec_test_type           varchar(400),
        rec_test_result_id      integer
                                constraint im_freelancers_rec_test_fk
                                references im_categories
);

-----------------------------------------------------------
-- Skills
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
	skill_id		not null 
				constraint im_fl_skills_skill_fk
				references im_categories,
	skill_type_id		not null 
				constraint im_fl_skills_skill_type_fk
				references im_categories,
	claimed_experience_id	integer
				constraint im_fl_skills_claimed_fk
				references im_categories,
	confirmed_experience_id	integer
				constraint im_fl_skills_conf_fk
				references im_categories,
	confirmation_user_id	integer
				constraint im_fl_skills_conf_user_fk
				references users,
	confirmation_date	date,
	-- "map" type of table
	constraint im_fl_skills_pk
	primary key (user_id, skill_id, skill_type_id)
);

create index im_freelance_skills_user_idx on im_freelance_skills(user_id);


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

prompt *** Creating Freelance Manager Profile
begin
   im_create_profile ('Freelance Managers','profile');
end;
/
show errors;


-----------------------------------------------------------
-- We need to define this function as a type of "join(..., ", ") to
-- get the list of skills for each user and skill type.
--
-- select im_freelance_skill_list(26,2000) from dual; -> 'es es_LA'
--
create or replace function im_freelance_skill_list ( 
	p_user_id IN number,
	p_skill_type_id IN number) 
RETURN char
IS
	v_skills			varchar(4000);
	v_skill				varchar(4000);

    CURSOR c_user_skills (v_user_id IN number, v_skill_type_id IN number) IS
	select	c.category	
	from	im_freelance_skills s,
		im_categories c
	where  	s.user_id=v_user_id
		and s.skill_type_id=v_skill_type_id
		and s.skill_id=c.category_id
	order by c.category;
BEGIN
	v_skills := '';
	FOR val IN c_user_skills(p_user_id, p_skill_type_id) LOOP
		v_skills := CONCAT(v_skills, ' ');
		v_skills := CONCAT(v_skills, val.category);
	END LOOP;
	RETURN v_skills;
END;
/
show errors;



-- Show the freelance information in users view page
--
declare
    v_plugin            integer;
begin
    v_plugin := im_component_plugin.new (
	plugin_name =>	'Users Freelance Component',
        package_name => 'intranet-freelance',
        page_url =>     '/intranet/users/view',
        location =>     'bottom',
        sort_order =>   10,
        component_tcl =>
        'im_freelance_info_component \
		$current_user_id \
                $user_id \
                $return_url \
		[im_opt_val freelance_view_name]'
    );
end;
/

-- Show the freelance skills in users view page
--
declare
    v_plugin            integer;
begin
    v_plugin := im_component_plugin.new (
	plugin_name =>	'Users Skills Component',
        package_name => 'intranet-freelance',
        page_url =>     '/intranet/users/view',
        location =>     'bottom',
        sort_order =>   20,
        component_tcl =>
        'im_freelance_skill_component \
		$current_user_id \
                $user_id \
                $return_url'
    );
end;
/

-- Show the freelance list in member-add page
--
declare
    v_plugin            integer;
begin
    v_plugin := im_component_plugin.new (
	plugin_name =>	'freelance list Component',
        package_name => 'intranet-freelance',
        page_url =>     '/intranet/member-add',
        location =>     'bottom',
        sort_order =>   10,
        component_tcl =>
        'im_freelance_member_select_component \
		$object_id \
                $return_url'
    );
end;
/



-- ------------------------------------------------------------
-- Backup reports
-- ------------------------------------------------------------

@../common/intranet-freelance-common.sql
@../common/intranet-freelance-backup.sql

