-- /packages/intranet-hr/sql/oracle/intranet-hr-create.sql
--
-- Project/Open HR Module, frank.bergmann@project-open.com, 030828
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

prompt *** Creating im_employees
create table im_employees (
	employee_id		integer 
				constraint im_employees_pk
				primary key 
				constraint im_employees_id_fk
				references parties,
	department_id		integer 
				constraint im_employees_department_fk
				references im_cost_centers,
	job_title		varchar(200),
	job_description		varchar(4000),
				-- part_time = 50% availability
	availability		integer,
	supervisor_id		integer 
				constraint im_employees_supervisor_fk
				references parties,
	ss_number		varchar(20),
	salary			number(12,3),
	social_security		number(12,3),
	insurance		number(12,3),
	other_costs		number(12,3),
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
	birthdate		date,
	skills			varchar(2000),
	first_experience	date,	
	years_experience	number(5,2),
	educational_history	varchar(4000),
	last_degree_completed	varchar(100),
				-- employee lifecycle management
	employee_status_id	integer
				constraint im_employees_rec_state_fk
				references im_categories,
	termination_reason	varchar(4000),
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
				references im_categories		
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
	parties pa,
	persons pe,
	im_employees e,
	groups g,
	group_distinct_member_map gdmm
where
	u.user_id = pa.party_id
	and u.user_id = pe.person_id
	and u.user_id = e.employee_id(+)
	and g.group_name = 'Employees'
	and gdmm.group_id = g.group_id
	and gdmm.member_id = u.user_id
;



-- stuff we need for the Org Chart
-- Oracle will pop a cap in our bitch ass if do CONNECT BY queries 
-- on im_users without these indices

create index im_employees_idx1 on im_employees(employee_id, supervisor_id);
create index im_employees_idx2 on im_employees(supervisor_id, employee_id);



prompt *** Creating im_supervises_p
create or replace function im_supervises_p(
	v_supervisor_id IN integer, 
	v_user_id IN integer)
return varchar
is
	v_exists_p char;
BEGIN
	select decode(count(1),0,'f','t') into v_exists_p
	from im_employees
	where employee_id = v_user_id
	and level > 1
	start with employee_id = v_supervisor_id
	connect by supervisor_id = PRIOR employee_id;
	return v_exists_p;
END im_supervises_p;
/
show errors


-- at given stages in the employee cycle, certain checkpoints
-- must be competed. For example, the employee should receive
-- an offer letter and it should be put in the employee folder

prompt *** Creating im_employee_checkpoints
create sequence im_employee_checkpoint_id_seq;
create table im_employee_checkpoints (
	checkpoint_id		integer
				constraint im_emp_checkp_pk
				primary key,
	stage			varchar(100) not null,
	checkpoint		varchar(500) not null
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
	check_date		date,
	check_note		varchar(1000),
		constraint im_emp_checkpoff_pk
		primary key (checkee, checkpoint_id)
);


prompt *** Creating User Freelance Component plugin
-- Show the freelance information in users view page
--
declare
    v_plugin            integer;
begin
    v_plugin := im_component_plugin.new (
        plugin_name =>  'User Employee Component',
        package_name => 'intranet-hr',
        page_url =>     '/intranet/users/view',
        location =>     'left',
        sort_order =>   60,
        component_tcl =>
        'im_employee_info_component \
                $user_id \
                $return_url \
                [im_opt_val employee_view_name]'
    );
end;
/



prompt *** Creating OrgChart menu entry
-- Add OrgChart to Users menu
declare
	v_user_orgchart_menu	integer;
	v_user_menu		integer;

        -- Groups
        v_employees     	integer;
        v_accounting    	integer;
        v_senman                integer;
        v_companies     	integer;
        v_freelancers   	integer;
        v_proman                integer;
        v_admins                integer;
begin
    select group_id into v_admins from groups where group_name = 'P/O Admins';
    select group_id into v_senman from groups where group_name = 'Senior Managers';
    select group_id into v_proman from groups where group_name = 'Project Managers';
    select group_id into v_accounting from groups where group_name = 'Accounting';
    select group_id into v_employees from groups where group_name = 'Employees';
    select group_id into v_companies from groups where group_name = 'Customers';
    select group_id into v_freelancers from groups where group_name = 'Freelancers';

    select menu_id
    into v_user_menu
    from im_menus
    where label='users';

    v_user_orgchart_menu := im_menu.new (
	package_name =>	'intranet-hr',
	name =>		'Org Chart',
	label =>	'users_org_chart',
	url =>		'/intranet-hr/org-chart?company_id=0',
	sort_order =>	5,
	parent_menu_id => v_user_menu
    );

    acs_permission.grant_permission(v_user_orgchart_menu, v_admins, 'read');
    acs_permission.grant_permission(v_user_orgchart_menu, v_senman, 'read');
    acs_permission.grant_permission(v_user_orgchart_menu, v_proman, 'read');
    acs_permission.grant_permission(v_user_orgchart_menu, v_accounting, 'read');
    acs_permission.grant_permission(v_user_orgchart_menu, v_employees, 'read');

end;
/
show errors;


------------------------------------------------------
-- HR Permissions
--

prompt *** Creating HR Profiles
begin
   im_create_profile ('HR Managers','profile');
end;
/
show errors;

prompt *** Creating Privileges
begin
    acs_privilege.create_privilege('view_hr','View HR','View HR');
    acs_privilege.add_child('admin', 'view_hr');
end;
/

prompt Initializing HR Permissions
BEGIN
    im_priv_create('view_hr',	'HR Managers');
    im_priv_create('view_hr',	'P/O Admins');
    im_priv_create('view_hr',	'Senior Managers');
    im_priv_create('view_hr',	'Accounting');
END;
/

commit;


------------------------------------------------------
-- Load common definitions and backup

@../common/intranet-hr-common.sql
@../common/intranet-hr-backup.sql
