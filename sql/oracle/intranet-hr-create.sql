-- /packages/intranet/sql/intranet.sql
--
-- Project/Open Core Module, fraber@fraber.de, 030828
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

create table im_employees (
	user_id			integer 
				primary key 
				references users,
	job_title		varchar(200),
	job_description	varchar(4000),
				-- is this person an official team leader?
	team_leader_p		char(1) 
				constraint im_employee_team_lead_con 
				check (team_leader_p in ('t','f')),
				-- can this person lead projects?
	project_lead_p	char(1) 
				constraint im_employee_project_lead_con check 
				(project_lead_p in ('t','f')),
	-- percent of a full time person this person works
	percentage		integer,
	supervisor_id		integer 
				references users,
	-- add a constraint to prevent a user from being her own supervisor
	group_manages		varchar(100),
	current_information	varchar(4000),
	--- send email if their information is too old
	last_modified		date default sysdate not null,
	ss_number		varchar(20),
	salary			number(9,2),
	salary_period		varchar(12) default 'month' 
				constraint im_employee_salary_period_con 
		check (salary_period in ('hour','day','week','month','year')),
	--- W2 information
	dependant_p		char(1) 
				constraint im_employee_dependant_p_con 
				check (dependant_p in ('t','f')),
	only_job_p		char(1) 
				constraint im_employee_only_job_p_con 
				check (only_job_p in ('t','f')),
	married_p		char(1) 
				constraint im_employee_married_p_con 
				check (married_p in ('t','f')),
	dependants		integer default 0,
	head_of_household_p	char(1) 
				constraint im_employee_head_of_house_con 
				check (head_of_household_p in ('t','f')),
	birthdate		date,
	skills			varchar(2000),
	first_experience	date,	
	years_experience	number(5,2),
	educational_history	varchar(4000),
	last_degree_completed	varchar(100),
	resume			clob,
	resume_html_p		char(1) 
				constraint im_employee_resume_html_p_con 
				check (resume_html_p in ('t','f')),
	start_date		date,
	-- when did the employee leave the company
	termination_date	date,
	received_offer_letter_p	char(1) 
				constraint im_employee_recv_offer_con 
				check(received_offer_letter_p in ('t','f')),
	returned_offer_letter_p char(1) 
				constraint im_employee_return_offer_con 
				check(returned_offer_letter_p in ('t','f')),
	-- did s/he sign the confidentiality agreement?
	signed_confidentiality_p char(1) 
				constraint im_employee_conf_p_con 
				check(signed_confidentiality_p	in ('t','f')),
	most_recent_review	date,
	most_recent_review_in_folder_p char(1) 
				constraint im_employee_recent_review_con 
			check(most_recent_review_in_folder_p in ('t','f')),
	featured_employee_approved_p char(1) 
				constraint featured_employee_p_con 
			check(featured_employee_approved_p in ('t','f')),
	featured_employee_approved_by integer 
				references users,
	featured_employee_blurb clob,
	featured_employee_blurb_html_p char(1) default 'f'
				constraint featured_emp_blurb_html_p_con 
				check (featured_employee_blurb_html_p in ('t','f')),
	referred_by 		references users,
	referred_by_recording_user integer 
				references users,
	experience_id		integer 
				references categories,
	source_id		integer 
				references categories,
	original_job_id		integer 
				references categories,
	current_job_id		integer 
				references categories,
	qualification_id	integer 
				references categories,
	department_id		integer 
				references categories,
	termination_reason	varchar(4000),
	voluntary_termination_p	char(1) default 'f'
				constraint iei_voluntary_termination_p_ck 
				check (voluntary_termination_p in ('t','f')),
	recruiting_blurb	clob,
	recruiting_blurb_html_p	char(1) default 'f'
				constraint recruiting_blurb_html_p_con 
				check (recruiting_blurb_html_p in ('t','f'))
);
create index im_employees_referred_idx on im_employees(referred_by);



-- stuff we need for the Org Chart
-- Oracle will pop a cap in our bitch ass if do CONNECT BY queries 
-- on im_us<ers without these indices

create index im_employees_idx1 on im_employees(user_id, supervisor_id);
create index im_employees_idx2 on im_employees(supervisor_id, user_id);

-- you can't do a JOIN with a CONNECT BY so we need a PL/SQL proc to
-- pull out user's name from user_id



create or replace function im_supervises_p(
	v_supervisor_id IN integer, 
	v_user_id IN integer)
return varchar
is
	v_exists_p char;
BEGIN
	select decode(count(1),0,'f','t') into v_exists_p
	from im_employees
	where user_id = v_user_id
	and level > 1
	start with user_id = v_supervisor_id
	connect by supervisor_id = PRIOR user_id;
	return v_exists_p;
END im_supervises_p;
/
show errors


-- at given stages in the employee cycle, certain checkpoints
-- must be competed. For example, the employee should receive
-- an offer letter and it should be put in the employee folder

create sequence im_employee_checkpoint_id_seq;

create table im_employee_checkpoints (
	checkpoint_id		integer 
				primary key,
	stage			varchar(100) not null,
	checkpoint		varchar(500) not null
);

create table im_emp_checkpoint_checkoffs (
	checkpoint_id		integer 
				references im_employee_checkpoints,
	checkee			integer not null 
				references users,
	checker			integer not null 
				references users,
	check_date		date,
	check_note		varchar(1000),
	primary key (checkee, checkpoint_id)
);


-- We need to keep track of in influx of employees.
-- For example, what employees have received offer letters?

create table im_employee_pipeline (
	user_id			integer 
				primary key 
				references users,
	state_id		integer not null 
				references categories,
	office_id		integer 
				references groups,
	team_id			integer 
				references groups,
	prior_experience_id 	integer 
				references categories,
	experience_id		integer 
				references categories,
	source_id		integer 
				references categories,		
	job_id			integer 
				references categories,
	projected_start_date	date,
	-- the person at the company in charge of reeling them in.
	recruiter_user_id	integer 
				references users,	
	referred_by		integer 
				references users,
	note			varchar(4000),
	probability_to_start	integer
);




-- keep track of the last_modified on im_employees
create or replace trigger im_employees_last_modif_tr
before update on im_employees
for each row
DECLARE
BEGIN
	:new.last_modified := sysdate;
END;
/
show errors;



