-- /packages/intranet-simple-survey/sql/postgres/intranet-simple-survey-create.sql
--
-- Copyright (c) 2003-2004 Project/Open
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
	acs_object_type		varchar(1000)
				constraint im_survsimp_omap_object_type_nn
				not null
				constraint im_survsimp_omap_object_type_fk
				references acs_object_types,
	biz_object_type_id	integer
				constraint im_survsimp_omap_biz_object_type_id_fk
				references im_categories,
	survey_id		integer
				constraint im_survsimp_omap_survey_id_nn
				not null
				constraint im_survsimp_omap_survey_id_fk
				references survsimp_surveys,
	name			varchar(1000),
	obligatory_p		char(1) default 'f'
				constraint im_survsimp_omap_obligatory_p_ck
				check(obligatory_p in ('t','f')),
	recurrence_tcl		varchar(4000),
	interviewee_profile_id	integer
				constraint im_survsimp_omap_interv_id_fk
				references groups,
	note			varchar(4000)
);
create index im_survsimp_object_map_acs_object_type_idx on im_survsimp_object_map (acs_object_type);
create index im_survsimp_object_map_biz_object_type_idx on im_survsimp_object_map (biz_object_type_id);
create index im_survsimp_object_map_survey_idx on im_survsimp_object_map (survey_id);

insert into im_survsimp_object_map (
	acs_object_type,
	biz_object_type_id,
	survey_id,
	name,
	obligatory_p,
	recurrence_tcl,
	interviewee_profile_id,
	note			
) values (
	'im_project',
	null,		-- all project subtypes
	(select survey_id from survsimp_surveys where short_name = 'pm_weekly'),
	'Weekly Project Report',
	't',
	'',		-- Recurrence
	467,		-- Project Managers
	'Please deliver weekly until Friday 11am'
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
select acs_privilege__add_child('write','survsimp_take_survey');



---------------------------------------------------------
-- delete potentially existing menus and plugins if this 
-- file is sourced multiple times during development...

select im_component_plugin__del_module('intranet-simple-survey');
select im_menu__del_module('intranet-simple-survey');



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
	''acs_object'',				-- object_type
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
	''acs_object'',				-- object_type
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




-------------------------------------------------------------
-- Menus
--

-- prompt *** intranet-costs: Create Finance Menu
-- Setup the "Finance" main menu entry
--
create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_admin_menu 		integer;

	-- Groups
	v_employees		integer;
	v_accounting		integer;
	v_senman		integer;
	v_customers		integer;
	v_freelancers		integer;
	v_proman		integer;
	v_admins		integer;
begin

    select group_id into v_admins from groups where group_name = ''P/O Admins'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';
    select group_id into v_accounting from groups where group_name = ''Accounting'';
    select group_id into v_customers from groups where group_name = ''Customers'';
    select group_id into v_freelancers from groups where group_name = ''Freelancers'';

    select menu_id
    into v_admin_menu
    from im_menus
    where label=''admin'';

    v_menu := im_menu__new (
	null,				-- menu_id
	''acs_object'',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	''intranet-simple-survey'',	-- package_name
	''admin_survsimp'',		-- label
	''Simple Surveys'',		-- name
	''/intranet-simple-survey/admin/index'',		-- url
	83,				-- sort_order
	v_admin_menu,			-- parent_menu_id
	null				-- visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');

    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

