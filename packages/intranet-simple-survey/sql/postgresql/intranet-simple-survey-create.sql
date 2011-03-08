-- /packages/intranet-simple-survey/sql/postgres/intranet-simple-survey-create.sql
--
-- Copyright (c) 2003-2008 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com



-----------------------------------------------------------
-- Simple Surveys - Object Linking Map
--
-- This map links "Business Object Types" (users, projects and
-- companies) and it's Type (provider, customer, internal, ...)
-- to Simple Surveys.
-- In the future we will also include there information about:
--	- Who whould fill out the survey
--	- When a person should fill out a survey
--
-- The problem with survey is not that much "restriction"
-- (make sure only the right persons fill out a survey)
-- but "enforcemente" (make sure the survey is filled out
-- when necessary, such as a PM report).
--
-- Permissions are being set at the survey level, not at
-- this mapping level.

create table im_survsimp_object_map (
		acs_object_type			varchar(1000)
						constraint im_survsimp_omap_object_type_nn
						not null
						constraint im_survsimp_omap_object_type_fk
						references acs_object_types,
		biz_object_type_id		integer
						constraint im_survsimp_omap_biz_object_type_id_fk
						references im_categories,
		survey_id			integer
						constraint im_survsimp_omap_survey_id_nn
						not null
						constraint im_survsimp_omap_survey_id_fk
						references survsimp_surveys,
		name				varchar(1000),
		obligatory_p			char(1) default 'f'
						constraint im_survsimp_omap_obligatory_p_ck
						check(obligatory_p in ('t','f')),
		recurrence_tcl			text,
		interviewee_profile_id  	integer
						constraint im_survsimp_omap_interv_id_fk
						references groups,
		note				text
);

create index im_survsimp_object_map_acs_object_type_idx on im_survsimp_object_map (acs_object_type);
create index im_survsimp_object_map_biz_object_type_idx on im_survsimp_object_map (biz_object_type_id);
create index im_survsimp_object_map_survey_idx on im_survsimp_object_map (survey_id);


-- insert into im_survsimp_object_map (
--       acs_object_type,
--       biz_object_type_id,
--       survey_id,
--       name,
--       obligatory_p,
--       recurrence_tcl,
--       interviewee_profile_id,
--       note
-- ) values (
--       'im_project',
--       null,           -- all project subtypes
--       (select survey_id from survsimp_surveys where short_name = 'pm_weekly'),
--       'Weekly Project Report',
--       't',
--       '',             -- Recurrence
--       467,            -- Project Managers
--       'Please deliver weekly until Friday 11am'
-- );



---------------------------------------------------------
-- Object - SurvSimp relationship
--

alter table survsimp_responses
add related_object_id integer references acs_objects;
create index im_survsimp_responses_object_id_idx
on survsimp_responses (related_object_id);

alter table survsimp_responses
add related_context_id integer references acs_objects;
create index im_survsimp_responses_context_id_idx
on survsimp_responses (related_context_id);



---------------------------------------------------------
-- Change the "survsimp_take_survey" from being
-- a child of the "read privilege" to a "write".
-- This is necessary, because the read privilege
-- is required for a user in order to be able to
-- access any page of the simple-survey package.
--
-- However, we want to set permissions on a
-- survey-by-survey level. The "write" privilege
-- is managable by the standard ]po[ security
-- maintenance screens.


select acs_privilege__remove_child('read','survsimp_take_survey');
select acs_privilege__add_child('write','survsimp_take_survey');




-----------------------------------------------------------
-- Simple Surveys - Schedules
--
-- This object represents the rules about who should fill out a survey
-- about whom in a project.


create table im_survsimp_schedules (
	schedule_id		integer
				constraint im_survsimp_schedules_pk
				primary key
				constraint im_survsimp_schedules_schedule_fk
				references acs_objects,

	-- The name of a scheduled survey, i.e. "Customer Satisfaction"
	schedule_name		text,
	-- What event should trigger the schedule? Available schedules:
	--	daily(XthDay, HourOfDay)
	--	weekly(XthWeek, DayOfWeek),
	--	monthly_day(XthMonth, DayOfMonth)
	--	monthly_week(XthMonth, XthWeek, DayOfWeek)
	--	yearly_month_daily(XthYear, MonthOfYear, DayOfMonth)
	--	yearly_month_weekly(XthYear, MonthOfYer, XthWeek, DayOfWeek)
	schedule_event		varchar(30),

	-- A TCL expression that needs to evaluate to 1.
	-- To restrict weekly PM report to active projects: "im_project_has_status $project_id 76"
	schedule_condition_tcl	text,

	-- The survey to be filled out.
	schedule_survey_id	integer
				constraint im_survsimp_schedules_survey_id_nn
				not null
				constraint im_survsimp_schedules_survey_id_fk
				references survsimp_surveys,

	-- On what type of object?
	schedule_context_object_type	varchar(100),

	-- The context of the survey. Typically this is a project.
	schedule_context_object_id	integer
				constraint im_survsimp_schedules_context_fk
				references acs_objects,
	-- Who should fill out the survey? The group is interpreted depending on the context_object
	schedule_subject_group	varchar(20)
				constraint im_survsimp_schedules_group_ck
				check(schedule_subject_group in (
					'owner', 'pm', 
					'employees', 'customers', 'providers'
				)),
	-- Who or what should be evaulated? The group is interpreted depending on the context_object.
	schedule_object_group	varchar(20)
				constraint im_survsimp_object_group_ck
				check(schedule_object_group in (
					'owner', 'pm', 
					'employees', 'customers', 'providers'
				)),

	schedule_obligatory_p	char(1) default 'f'
				constraint im_survsimp_schedules_obligatory_p_ck
				check(schedule_obligatory_p in ('t','f')),

	schedule_status_id	integer not null
				constraint im_survsimp_schedules_status_fk
				references im_categories,
	schedule_type_id		integer not null
				constraint im_survsimp_schedules_type_fk
				references im_categories,

	description		text,
	note			text
);

-- Avoid duplicate entries.
create unique index im_survsimp_schedule_un 
on im_survsimp_schedules (
	schedule_subject_group, 
	schedule_object_group, 
	schedule_survey_id, 
	schedule_context_object_id
);



-----------------------------------------------------------
-- Simple Surveys - Requests
--
-- This object represents the need that one specific person should
-- fill out a survey about a certain object. 

create table im_survsimp_user_schedule_map (
	request_user_id		integer
				constraint im_survsimp_requests_user_fk
				references persons,
	request_object_id	integer
				constraint im_survsimp_requests_object_fk
				references acs_objects,
	request_schedule_id	integer
				constraint im_survsimp_requests_schedule_fk
				references im_survsimp_schedules
);


---------------------------------------------------------
-- Change the "survsimp_take_survey" from being
-- a child of the "read privilege" to a "write".
-- This is necessary, because the read privilege
-- is required for a user in order to be able to
-- access any page of the simple-survey package.
--
-- However, we want to set permissions on a 
-- survey-by-survey level. The "write" privilege
-- is managable by the standard ]po[ security 
-- maintenance screens.


select acs_privilege__remove_child('read','survsimp_take_survey');
select acs_privilege__remove_child('write','survsimp_take_survey');
select acs_privilege__add_child('write','survsimp_take_survey');


---------------------------------------------------------
-- Register components:
--	- at project pages
--	- An admin menu at the ]po[ admin page ('/intranet/admin/index')
--

create or replace function inline_0 ()
returns integer as ' 
declare
	v_plugin		integer;
begin
	v_plugin := im_component_plugin__new (
		null,					-- plugin_id
		''im_component_plugin'',		-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creation_ip
		null,					-- context_id
		''Project Survey Component'',		-- plugin_name
		''intranet-simple-survey'',		-- package_name
		''right'',				-- location
		''/intranet/projects/view'',		-- page_url
		null,					-- view_name
		50,					-- sort_order
		''im_survsimp_component $project_id''	-- component_tcl
	);
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
	v_plugin		integer;
begin
	v_plugin := im_component_plugin__new (
		null,					-- plugin_id
		''im_component_plugin'',		-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creation_ip
		null,					-- context_id
		''Company Survey Component'',		-- plugin_name
		''intranet-simple-survey'',		-- package_name
		''right'',				-- location
		''/intranet/companies/view'',		-- page_url
		null,					-- view_name
		20,					-- sort_order
		''im_survsimp_component $company_id''   -- component_tcl
	);
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



create or replace function inline_0 ()
returns integer as '
declare
	v_plugin		integer;
begin
	v_plugin := im_component_plugin__new (
		null,					-- plugin_id
		''acs_object'',				-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creation_ip
		null,					-- context_id
		''User Survey Component'',		-- plugin_name
		''intranet-simple-survey'',		-- package_name
		''right'',				-- location
		''/intranet/users/view'',		-- page_url
		null,					-- view_name
		120,					-- sort_order
		''im_survsimp_component $user_id''	-- component_tcl
	);
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




create or replace function inline_0 ()
returns integer as '
declare
	v_plugin		integer;
begin
	v_plugin := im_component_plugin__new (
		null,					-- plugin_id
		''im_component_plugin'',		-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creation_ip
		null,					-- context_id
		''Ticket Survey Component'',		-- plugin_name
		''intranet-simple-survey'',		-- package_name
		''right'',				-- location
		''/intranet-helpdesk/new'',		-- page_url
		null,					-- view_name
		120,					-- sort_order
		''im_survsimp_component $ticket_id''	-- component_tcl
	);
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();





-------------------------------------------------------------
-- Menus
--

create or replace function inline_0 ()
returns integer as '
declare
	v_menu			integer;
	v_admin_menu 		integer;
	v_employees		integer;
	v_accounting		integer;
	v_senman		integer;
	v_customers		integer;
	v_freelancers		integer;
	v_admins		integer;
begin

	select group_id into v_admins from groups where group_name = ''P/O Admins'';
	select group_id into v_senman from groups where group_name = ''Senior Managers'';
	select group_id into v_accounting from groups where group_name = ''Accounting'';
	select group_id into v_customers from groups where group_name = ''Customers'';
	select group_id into v_freelancers from groups where group_name = ''Freelancers'';

	select menu_id into v_admin_menu from im_menus where label=''admin'';

	v_menu := im_menu__new (
		null,					-- menu_id
		''im_menu'',				-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creation_ip
		null,					-- context_id
		''intranet-simple-survey'',		-- package_name
		''admin_survsimp'',			-- label
		''Simple Surveys'',			-- name
		''/intranet-simple-survey/admin/index'', -- url
		83,					-- sort_order
		v_admin_menu,				-- parent_menu_id
		null					-- visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


-- Setup the Simple Survey section in the reports page
--
select im_menu__new (
	null,						-- p_menu_id
	'im_menu',					-- object_type
	now(),						-- creation_date
	null,						-- creation_user
	null,						-- creation_ip
	null,						-- context_id
	'intranet-simple-survey',			-- package_name
	'reporting-simple-survey',			-- label
	'Simple Surveys',				-- name
	'/intranet-simple-survey/index?',		-- url
	270,						-- sort_order
	(select menu_id from im_menus where label = 'reporting'),
	null						-- p_visible_tcl
);

SELECT acs_permission__grant_permission(
        (select menu_id from im_menus where label = 'reporting-simple-survey'),
        (select group_id from groups where group_name = 'Employees'),
        'read'
);




-- Setup the Simple Survey Report in Menus
--
create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_reporting_other_menu 		integer;

	-- Groups
	v_employees		integer;
	v_accounting		integer;
	v_senman		integer;
	v_customers		integer;
	v_freelancers		integer;
	v_proman		integer;
	v_admins		integer;
begin
	select group_id into v_senman from groups where group_name = ''Senior Managers'';
	select group_id into v_proman from groups where group_name = ''Project Managers'';
	select group_id into v_accounting from groups where group_name = ''Accounting'';

	select menu_id into v_reporting_other_menu from im_menus where label=''reporting-simple-survey'';

	v_menu := im_menu__new (
		null,				-- menu_id
		''im_menu'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-simple-survey'',	-- package_name
		''reporting_survsimp_results'',	-- label
		''Simple Survey Results'',	-- name
		''/intranet-simple-survey/reporting/survsimp-results'',	-- url
		10,				-- sort_order
		v_reporting_other_menu,		-- parent_menu_id
		null				-- visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-- Setup the Simple Survey Report in Menus
--
create or replace function inline_0 ()
returns integer as '
declare
	v_menu			integer;
	v_project_menu 		integer;
	v_employees		integer;
begin
	select group_id into v_employees from groups where group_name = ''Employees'';
	select menu_id into v_project_menu from im_menus where label=''projects'';

	v_menu := im_menu__new (
		null,							-- menu_id
		''im_menu'',						-- object_type
		now(),							-- creation_date
		null,							-- creation_user
		null,							-- creation_ip
		null,							-- context_id
		''intranet-simple-survey'',				-- package_name
		''project_reports'',					-- label
		''Project Reports'',					-- name
		''/intranet-simple-survey/reporting/project-reports'',	-- url
		-5,							-- sort_order
		v_project_menu,						-- parent_menu_id
		null							-- visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


