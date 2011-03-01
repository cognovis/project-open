-- /packages/intranet-hr/sql/postgresql/intranet-hr-create.sql
--
-- ]project-open[ HR Module
--
-- frank.bergmann@project-open.com, 030828
-- A complete revision of June 1999 by dvr@arsdigita.com
--
-- Copyright (C) 1999-2004 ArsDigita, Frank Bergmann and others
--
-- This program is free software. You can redistribute it 
-- and/or modify it under the terms of the GNU General 
-- Public License as published by the Free Software Foundation; 
-- either version 2 of the License, or (at your option) 
-- any later version. This program is distributed in the 
-- hope that it will be useful, but WITHOUT ANY WARRANTY; 
-- without even the implied warranty of MERCHANTABILITY or 
-- FITNESS FOR A PARTICULAR PURPOSE. 
-- See the GNU General Public License for more details.


----------------------------------------------------
-- Employees
--
-- Employees is a subclass of Users
-- So according to the AC conventions, there is an
-- additional table *_info which contains the additional
-- fields.
--

-- prompt *** Creating im_employees
create table im_employees (
	employee_id		integer 
				constraint im_employees_pk
				primary key 
				constraint im_employees_id_fk
				references parties,
	department_id		integer 
				constraint im_employees_department_fk
				references acs_objects,
	job_title		text,
	job_description		text,
				-- part_time = 50% availability
	availability		integer,
	supervisor_id		integer 
				constraint im_employees_supervisor_fk
				references parties,
	ss_number		varchar(20),
	salary			numeric(12,3),
	social_security		numeric(12,3),
	insurance		numeric(12,3),
	other_costs		numeric(12,3),
	hourly_cost		numeric(12,3),
	currency		char(3)
				constraint im_employees_currency_fk
				references currency_codes,
	salary_period		varchar(12) default 'month' 
				constraint im_employees_salary_period_ck
				check (salary_period in ('hour','day','week','month','year')),
	salary_payments_per_year integer default 12,
				--- W2 information
	dependant_p		char(1) 
				constraint im_employees_dependant_p_con 
				check (dependant_p in ('t','f')),
	only_job_p		char(1) 
				constraint im_employees_only_job_p_con 
				check (only_job_p in ('t','f')),
	married_p		char(1) 
				constraint im_employees_married_p_con 
				check (married_p in ('t','f')),
	dependants		integer,
	head_of_household_p	char(1)
				constraint im_employees_head_of_house_con 
				check (head_of_household_p in ('t','f')),
	birthdate		timestamptz,
	skills			text,
	first_experience	timestamptz,	
	years_experience	numeric(5,2),
	educational_history	text,
	last_degree_completed	text,
				-- employee lifecycle management
	employee_status_id	integer
				constraint im_employees_rec_state_fk
				references im_categories,
	termination_reason	text,
	voluntary_termination_p	char(1) default 'f'
				constraint im_employees_vol_term_ck
				check (voluntary_termination_p in ('t','f')),
				-- did s/he sign non disclosure agreement?
	signed_nda_p		char(1)
				constraint im_employees_conf_p_con 
				check(signed_nda_p in ('t','f')),
	referred_by 		integer
				constraint im_employees_referred_fk 
				references parties,
	experience_id		integer 
				constraint im_employees_experience_fk
				references im_categories,
	source_id		integer 
				constraint im_employees_source_fk
				references im_categories,
	original_job_id		integer 
				constraint im_employees_org_job_fk
				references im_categories,
	current_job_id		integer 
				constraint im_employees_current_job_fk
				references im_categories,
	qualification_id	integer 
				constraint im_employees_qualification_fk
				references im_categories,
	vacation_days_per_year	numeric(12,2),
	vacation_balance	numeric(12,2)
);
create index im_employees_referred_idx on im_employees(referred_by);

alter table im_employees
add constraint im_employees_superv_ck
check (supervisor_id != employee_id);


-- Select all information for active employees
-- (member of Employees group).
--
create or replace view im_employees_active as
select
	u.*,
	e.*,
	pa.*,
	pe.*
from
	users u,
	group_distinct_member_map gdmm,
	parties pa,
	persons pe
	LEFT OUTER JOIN im_employees e ON (pe.person_id = e.employee_id)
where
	u.user_id = pa.party_id and
	u.user_id = pe.person_id and
	u.user_id = e.employee_id and
	u.user_id = gdmm.member_id and
	gdmm.group_id in (select group_id from groups where group_name = 'Employees') and
	u.user_id in (
		select  r.object_id_two
		from    acs_rels r,
			membership_rels mr
		where   r.rel_id = mr.rel_id and
			r.object_id_one in (
				select group_id
				from groups
				where group_name = 'Registered Users'
			) and mr.member_state = 'approved'
	)
;


-- stuff we need for the Org Chart
-- Oracle will pop a cap in our bitch ass if do CONNECT BY queries 
-- on im_users without these indices

create index im_employees_idx1 on im_employees(employee_id, supervisor_id);
create index im_employees_idx2 on im_employees(supervisor_id, employee_id);


create or replace function im_supervises_p (integer, integer)
returns char as '
DECLARE
	p_supervisor_id		alias for $1;
	p_user_id		alias for $2;

	v_user_id		integer;
	v_exists_p		char;
	v_count			integer;
BEGIN
	v_count := 0;
	v_user_id := p_user_id;

	WHILE v_count < 100 and v_user_id is not null LOOP
		IF v_user_id = p_supervisor_id THEN return ''t''; END IF;

		select	e.supervisor_id into v_user_id
		from	im_employees e
		where	e.employee_id = v_user_id;

		v_count := v_count + 1;
	END LOOP;

	return ''f'';
END;' language 'plpgsql';


-- at given stages in the employee cycle, certain checkpoints
-- must be competed. For example, the employee should receive
-- an offer letter and it should be put in the employee folder

create sequence im_employee_checkpoint_id_seq;
create table im_employee_checkpoints (
	checkpoint_id		integer
				constraint im_emp_checkp_pk
				primary key,
	stage			varchar(100) not null,
	checkpoint		text not null
);

create table im_emp_checkpoint_checkoffs (
	checkpoint_id		integer 
				constraint im_emp_checkpoff_checkp_fk
				references im_employee_checkpoints,
	checkee			integer not null 
				constraint im_emp_checkpoff_checkee_fk
				references parties,
	checker			integer not null 
				constraint im_emp_checkpoff_checker_fk
				references parties,
	check_date		timestamptz,
	check_note		text,
		constraint im_emp_checkpoff_pk
		primary key (checkee, checkpoint_id)
);


-- Show the freelance information in users view page
--
select im_component_plugin__new (
	null,					-- plugin_id
	'acs_object',				-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creattion_ip
	null,					-- context_id
	
	'User Employee Component',		-- plugin_name
	'intranet-hr',				-- package_name
	'left',					-- location
	'/intranet/users/view',			-- page_url
	null,					-- view_name
	60,					-- sort_order
	'im_employee_info_component $user_id_from_search $return_url [im_opt_val employee_view_name]'
);

-- prompt *** Creating OrgChart menu entry
-- Add OrgChart to Users menu
create or replace function inline_0 ()
returns integer as '
declare
	v_user_orgchart_menu	integer;
	v_user_menu		integer;

	-- Groups
	v_employees		integer;
	v_accounting		integer;
	v_senman		integer;
	v_customers		integer;
	v_freelancers   	integer;
	v_proman		integer;
	v_admins		integer;
begin
	select group_id into v_admins from groups where group_name = ''P/O Admins'';
	select group_id into v_senman from groups where group_name = ''Senior Managers'';
	select group_id into v_proman from groups where group_name = ''Project Managers'';
	select group_id into v_accounting from groups where group_name = ''Accounting'';
	select group_id into v_employees from groups where group_name = ''Employees'';
	select group_id into v_customers from groups where group_name = ''Customers'';
	select group_id into v_freelancers from groups where group_name = ''Freelancers'';

	select menu_id
	into v_user_menu
	from im_menus
	where label=''users'';

	v_user_orgchart_menu := im_menu__new (
		null,					-- menu_id
		''acs_object'',				-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creation_ip
		null,					-- context_id
		''intranet-hr'',			-- package_name
		''users_org_chart'',			-- label
		''Org Chart'',				-- name
		''/intranet-hr/org-chart?company_id=0'', -- url
		5,					-- sort_order
		v_user_menu,				-- parent_menu_id
		null					-- visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_user_orgchart_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_user_orgchart_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_user_orgchart_menu, v_proman, ''read'');
	PERFORM acs_permission__grant_permission(v_user_orgchart_menu, v_accounting, ''read'');
	PERFORM acs_permission__grant_permission(v_user_orgchart_menu, v_employees, ''read'');
	return 0;
end;' language 'plpgsql';

select inline_0 ();
drop function inline_0 ();


------------------------------------------------------
-- HR Permissions
--

select im_create_profile ('HR Managers','profile');

select acs_privilege__create_privilege('view_hr','View HR','View HR');
select acs_privilege__add_child('admin', 'view_hr');

select im_priv_create('view_hr', 'HR Managers');
select im_priv_create('view_hr', 'P/O Admins');
select im_priv_create('view_hr', 'Senior Managers');
select im_priv_create('view_hr', 'Accounting');



------------------------------------------------------
-- Load common definitions and backup

\i ../common/intranet-hr-common.sql
\i ../common/intranet-hr-backup.sql

