-- /packages/intranet-timesheet2-workflow/sql/postgresql/intranet-timesheet2-workflow-create.sql
--
-- Copyright (c) 2003-2007 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


\i workflow-timesheet_approval_wf-create.sql
\i workflow-vacation_approval_wf-create.sql


-----------------------------------------------------------
-- Workflow Confirmation Object
--
-- Allows to use a workflow to confirm hours between start_date
-- and end_date.


SELECT acs_object_type__create_type (
	'im_timesheet_conf_object',	-- object_type
	'Timesheet Confirmation Object', -- pretty_name
	'Timesheet Confirmation Objects', -- pretty_plural
	'acs_object',			-- supertype
	'im_timesheet_conf_objects',	-- table_name
	'conf_id',			-- id_column
	'intranet-timesheet2-workflow',	-- package_name
	'f',				-- abstract_p
	null,				-- type_extension_table
	'im_timesheet_conf_object__name' -- name_method
);


insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_timesheet_conf_object', 'im_timesheet_conf_objects', 'conf_id');


-- Setup status and type columns for im_user_confs
update acs_object_types set
        status_column = 'conf_status_id',
        type_column='conf_type_id',
        status_type_table='im_timesheet_conf_objects'
where object_type = 'im_timesheet_conf_object';


insert into im_biz_object_urls (object_type, url_type, url) values (
'im_timesheet_conf_object','view',
'/intranet-timesheet2-workflow/conf-objects/new?display_mode=display&conf_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_timesheet_conf_object','edit',
'/intranet-timesheet2-workflow/conf-objects/new?display_mode=edit&conf_id=');



create table im_timesheet_conf_objects (
	conf_id		integer
			constraint im_timesheet_conf_id_pk
			primary key
			constraint im_timesheet_conf_id_fk
			references acs_objects,

	conf_project_id	integer
			constraint im_timesheet_conf_project_nn
			not null
			constraint im_timesheet_conf_project_fk
			references im_projects,
	conf_user_id	integer
			constraint im_timesheet_conf_user_nn
			not null
			constraint im_timesheet_conf_user_fk
			references users,
	start_date	date 
			constraint im_timesheet_conf_start_date_nn
			not null,
	end_date	date 
			constraint im_timesheet_conf_end_date_nn
			not null,

	conf_status_id	integer 
			constraint im_timesheet_conf_status_nn
			not null
			constraint im_timesheet_conf_status_fk
			references im_categories,
	conf_type_id	integer 
			constraint im_timesheet_conf_type_nn
			not null
			constraint im_timesheet_conf_type_fk
			references im_categories
);


-- Allow duplicate entries - meanwhile
-- create unique index im_timesheet_conf_un_idx on im_timesheet_conf_objects(conf_project_id, conf_user_id, start_date);





-----------------------------------------------------------
-- Add confirmation object to hours to keep status
--
-- Add an conf_object_id field to im_hours to mark confirmed hours
alter table im_hours add column conf_object_id integer 
constraint im_hours_conf_obj_fk references im_timesheet_conf_objects;

-- And add an index, as access to conf_obj is quite frequent.
create index im_hours_conf_obj_idx on im_hours(conf_object_id);





-----------------------------------------------------------
-- Privileges
--

-- view_timesheet_conf_objects_all restricts possibility to see timesheet_conf_objects of others
SELECT acs_privilege__create_privilege(
	'view_timesheet_conf_all',
	'View Timesheet Conf Objects All',
	'View Timesheet Conf Objects All'
);
SELECT acs_privilege__add_child('admin', 'view_timesheet_conf_all');


-----------------------------------------------------------
-- Create, Drop and Name Plpg/SQL functions
--
-- These functions represent crator/destructor
-- functions for the OpenACS object system.


create or replace function im_timesheet_conf_object__name(integer)
returns varchar as '
DECLARE
	p_conf_id		alias for $1;
	v_name			varchar;
BEGIN
	select	im_name_from_user_id(conf_user_id) || '' @ '' || 
		p.project_name || '' ('' ||
		to_char(co.start_date, ''YYYY-MM-DD'') || ''-'' ||
		to_char(co.end_date, ''YYYY-MM-DD'') || '') ''
	into	v_name
	from	im_timesheet_conf_objects co,
		im_projects p
	where	conf_id = p_conf_id
		and co.conf_project_id = p.project_id;

	return v_name;
end;' language 'plpgsql';


create or replace function im_timesheet_conf_object__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	integer, integer, date, date, integer, integer
) returns integer as '
DECLARE
	p_conf_id	alias for $1;
	p_object_type   alias for $2;
	p_creation_date alias for $3;
	p_creation_user alias for $4;
	p_creation_ip   alias for $5;
	p_context_id	alias for $6;

	p_conf_project_id alias for $7;
	p_conf_user_id	alias for $8;
	p_start_date	alias for $9;
	p_end_date	alias for $10;

	p_conf_type_id	alias for $11;		
	p_conf_status_id alias for $12;

	v_conf_id	integer;
BEGIN
	v_conf_id := acs_object__new (
		p_conf_id,		-- object_id
		p_object_type,		-- object_type
		p_creation_date,	-- creation_date
		p_creation_user,	-- creation_user
		p_creation_ip,		-- creation_ip
		p_context_id,		-- context_id
		''t''			-- security_inherit_p
	);

	insert into im_timesheet_conf_objects (
		conf_id,
		conf_project_id, conf_user_id,
		start_date, end_date,
		conf_type_id, conf_status_id
	) values (
		v_conf_id,
		p_conf_project_id, p_conf_user_id,
		p_start_date, p_end_date,
		p_conf_type_id,	p_conf_status_id
	);

	return v_conf_id;
END;' language 'plpgsql';


create or replace function im_timesheet_conf_object__delete(integer)
returns integer as '
DECLARE
	p_conf_id	alias for $1;
BEGIN
	-- remove pointers to this object from im_hours
	update	im_hours
	set	conf_object_id = null
	where	conf_object_id = p_conf_id;

	-- Delete workflow tokens for cases around this object
	delete from wf_tokens 
	where case_id in (select case_id from wf_cases where object_id = p_conf_id);

	-- Delete workflow cases of this object.
	delete from wf_cases where object_id = p_conf_id;

	-- Delete any data related to the object
	delete	from im_timesheet_conf_objects
	where	conf_id = p_conf_id;

	-- Finally delete the object iself
	PERFORM acs_object__delete(p_conf_id);

	return 0;
end;' language 'plpgsql';


-----------------------------------------------------------
-- Type and Status
--
-- Create categories for Notes type and status.
-- Status acutally is not use, so we just define "active"

-- Here are the ranges for the constants as defined in
-- /intranet-core/sql/common/intranet-categories.sql
--
-- Please contact support@project-open.com if you need to
-- reserve a range of constants for a new module.
--
-- 17000-17099  Intranet Timesheet Workflow Status (100)
-- 17100-17199  Intranet Timesheet Workflow Type (100)
-- 17200-17999  Reserved (8000)


insert into im_categories(category_id, category, category_type) 
values (17000, 'Requested', 'Intranet Timesheet Conf Status');
insert into im_categories(category_id, category, category_type) 
values (17010, 'Active', 'Intranet Timesheet Conf Status');
insert into im_categories(category_id, category, category_type) 
values (17020, 'Rejected', 'Intranet Timesheet Conf Status');
insert into im_categories(category_id, category, category_type) 
values (17090, 'Deleted', 'Intranet Timesheet Conf Status');


insert into im_categories(category_id, category, category_type) 
values (17100, 'Timesheet', 'Intranet Timesheet Conf Type');


-----------------------------------------------------------
-- Create views for shortcut
--

create or replace view im_timesheet_conf_object_status as
select	category_id as conf_status_id, category as conf_status
from	im_categories
where	category_type = 'Intranet Timesheet Conf Status'
	and (enabled_p is null or enabled_p = 't');

create or replace view im_timesheet_conf_object_types as
select	category_id as conf_type_id, category as conf_type
from	im_categories
where	category_type = 'Intranet Timesheet Conf Type'
	and (enabled_p is null or enabled_p = 't');



-----------------------------------------------------------
-- Component Plugin
--
-- Create a Timesheet Conf plugin for the ProjectViewPage.




-- ------------------------------------------------------
-- Workflow Graph & Journal on Absence View Page
-- ------------------------------------------------------

SELECT  im_component_plugin__new (
	null,					-- plugin_id
	'acs_object',				-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id

	'Timesheet Confirmation Workflow',	-- component_name
	'intranet-timesheet2-workflow',		-- package_name
	'right',				-- location
	'/intranet-timesheet2-workflow/conf-objects/new',	-- page_url
	null,					-- view_name
	10,					-- sort_order
	'im_workflow_graph_component -object_id $conf_id'
);

SELECT  im_component_plugin__new (
	null,					-- plugin_id
	'acs_object',				-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id

	'Timesheet Confirmation Journal',			-- component_name
	'intranet-timesheet2-workflow',		-- package_name
	'bottom',				-- location
	'/intranet-timesheet2-workflow/conf-objects/new',	-- page_url
	null,					-- view_name
	100,					-- sort_order
	'im_workflow_journal_component -object_id $conf_id'
);



-- SELECT im_component_plugin__new (
-- 	null,				-- plugin_id
-- 	'acs_object',			-- object_type
-- 	now(),				-- creation_date
-- 	null,				-- creation_user
-- 	null,				-- creation_ip
-- 	null,				-- context_id
-- 	'Project Timesheet Conf',		-- plugin_name
-- 	'intranet-timesheet2-workflow',		-- package_name
-- 	'right',			-- location
-- 	'/intranet/projects/view',	-- page_url
-- 	null,				-- view_name
-- 	90,				-- sort_order
-- 	'im_timesheet_conf_objects_project_component -object_id $project_id'	-- component_tcl
-- );

-- update im_component_plugins 
-- set title_tcl = 'lang::message::lookup "" intranet-timesheet2-workflow.Project_Timesheet Conf "Project Timesheet Conf"'
-- where plugin_name = 'Project Timesheet Conf';


-- SELECT im_component_plugin__new (
-- 	null,				-- plugin_id
-- 	'acs_object',			-- object_type
-- 	now(),				-- creation_date
-- 	null,				-- creation_user
-- 	null,				-- creation_ip
-- 	null,				-- context_id
-- 	'Company Timesheet Conf',		-- plugin_name
-- 	'intranet-timesheet2-workflow',		-- package_name
-- 	'right',			-- location
-- 	'/intranet/companies/view',	-- page_url
-- 	null,				-- view_name
-- 	90,				-- sort_order
-- 	'im_timesheet_conf_objects_project_component -object_id $company_id'	-- component_tcl
-- );

--  update im_component_plugins 
-- set title_tcl = 'lang::message::lookup "" intranet-timesheet2-workflow.Company_Timesheet Conf "Company Timesheet Conf"'
-- where plugin_name = 'Company Timesheet Conf';


-----------------------------------------------------------
-- Add "Start Timesheet Workflow" link to TimesheetNewPage
--

-- create or replace function inline_0 ()
-- returns integer as '
-- declare
-- 	-- Menu IDs
-- 	v_menu			integer;
-- 	v_main_menu		integer;
-- 
-- 	-- Groups
-- 	v_employees		integer;
-- 	v_accounting		integer;
-- 	v_senman		integer;
-- 	v_proman		integer;
-- 	v_admins		integer;
-- BEGIN
-- 	-- Get some group IDs
-- 	select group_id into v_admins from groups where group_name = ''P/O Admins'';
-- 	select group_id into v_senman from groups where group_name = ''Senior Managers'';
-- 	select group_id into v_proman from groups where group_name = ''Project Managers'';
-- 	select group_id into v_accounting from groups where group_name = ''Accounting'';
-- 	select group_id into v_employees from groups where group_name = ''Employees'';
-- 
-- 	-- Determine the main menu. "Label" is used to identify menus.
-- 	select menu_id into v_main_menu
-- 	from im_menus where label = ''timesheet_hours_new_admin'';
-- 
-- 	-- Create the menu.
-- 	v_menu := im_menu__new (
-- 		null,					-- p_menu_id
-- 		''acs_object'',				-- object_type
-- 		now(),					-- creation_date
-- 		null,					-- creation_user
-- 		null,					-- creation_ip
-- 		null,					-- context_id
-- 		''intranet-timesheet2-workflow'',	-- package_name
-- 		''timesheet_hours_new_start_workflow'',	-- label
-- 		''Start Confirmation Workflow'',		-- name
-- 		''/intranet-timesheet2-workflow/conf-objects/new-workflow?'',	-- url
-- 		15,					-- sort_order
-- 		v_main_menu,				-- parent_menu_id
-- 		null					-- p_visible_tcl
-- 	);
-- 
-- 	-- Grant read permissions to most of the system
-- 	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
-- 	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
-- 	PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
-- 	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
-- 	PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');
-- 
-- 	return 0;
-- end;' language 'plpgsql';
-- select inline_0 ();
-- drop function inline_0 ();

-- upgrade-4.0.3.0.0-4.0.3.0.1.sql

SELECT acs_log__debug('/packages/intranet-timesheet2-workflow/sql/postgresql/upgrade/upgrade-4.0.3.0.0-4.0.3.0.1.sql','');

CREATE OR REPLACE FUNCTION im_absence_notify_applicant_not_approved(integer, character varying, character varying)
  RETURNS integer AS
$BODY$
declare
        p_case_id               alias for $1;
        p_transition_key        alias for $2;
	p_custom_arg            alias for $3;

        v_task_id               integer;        v_case_id               integer;
        v_creation_ip           varchar;        v_creation_user         integer;
        v_object_id             integer;        v_object_type           varchar;
        v_journal_id            integer;        v_name_creation_user    varchar;
        v_transition_key        varchar;        v_workflow_key          varchar;
        v_group_id              integer;        v_group_name            varchar;
        v_task_owner            integer;

	v_absence_id		integer;

	v_start_date		text;		 
	v_end_date		text;
	v_description		text;

	v_url			text;
	v_base_url		text;

        v_object_name           text;
        v_party_from            parties.party_id%TYPE;
        v_party_to              parties.party_id%TYPE;
        v_subject               text;
        v_body                  text;
        v_request_id            integer;

        v_locale                text;
        v_count                 integer;

begin
        RAISE NOTICE 'im_absence_notify_applicant_not_approved: enter - p_case_id=%, p_transition_key=%, p_custom_arg=%', p_case_id, p_transition_key, p_custom_arg;

        -- Select out some frequently used variables of the environment
        select  c.object_id, c.workflow_key, co.creation_user, task_id, c.case_id, co.object_type, co.creation_ip
        into    v_object_id, v_workflow_key, v_creation_user, v_task_id, v_case_id, v_object_type, v_creation_ip
        from    wf_tasks t, wf_cases c, acs_objects co
        where   c.case_id = p_case_id
                and c.case_id = co.object_id
                and t.case_id = c.case_id
                and t.workflow_key = c.workflow_key
                and t.transition_key = p_transition_key;

        v_party_from := -1;

        -- Get locale of user
        select  language_preference into v_locale
        from    user_preferences
        where   user_id = v_creation_user;

	IF v_locale IS NULL THEN
		v_locale := 'en_US';
	END IF; 

        -- ------------------------------------------------------------
        -- Try with specific translation first
        v_subject := 'Notification_Subject_Notify_Applicant_Absence_Not_Approved';
        v_subject := acs_lang_lookup_message(v_locale, 'intranet-timesheet2-workflow', v_subject);

        -- Fallback to generic (no transition key) translation
        IF substring(v_subject from 1 for 7) = 'MISSING' THEN
                v_subject := 'Your application for an absence';
        END IF;

        -- Replace variables
        -- v_subject := replace(v_subject, '%object_name%', v_object_name);
        -- v_subject := replace(v_subject, '%transition_name%', v_transition_name);

        -- ------------------------------------------------------------
        -- Try with specific translation first
        v_body := 'Notification_Body_Notify_Applicant_Absence_Not_Approved';
        v_body := acs_lang_lookup_message(v_locale, 'intranet-timesheet2-workflow', v_body);

        -- Fallback to generic (no transition key) translation
        IF substring(v_body from 1 for 7) = 'MISSING' THEN
                v_body := 'Your application for an absence has not been approved:';
        END IF;

        -- Replace variables
        -- v_body := replace(v_body, '%object_name%', v_object_name);
        -- v_body := replace(v_body, '%transition_name%', v_transition_name);

	-- get absence_id 
	select object_id into v_absence_id from wf_cases where case_id = p_case_id; 

	-- get URL of absence
	select 	attr_value 
	into 	v_base_url 
	from 
		apm_parameter_values pv,
		apm_parameters p
	where 
                p.package_key = 'acs-kernel' and
                p.parameter_name = 'SystemURL' and
                pv.parameter_id = p.parameter_id;

	v_url := v_base_url || 'intranet-timesheet2/absences/new?form_mode=display&absence_id=' || v_absence_id;

	-- get info about absence 
       	select
                to_char(start_date,'YYYY-MM-DD'),
                to_char(end_date,'YYYY-MM-DD'),
		COALESCE(v_description, '(none)')
       	into v_start_date, v_end_date, v_description
       	from im_user_absences where absence_id = v_absence_id;

	v_body := v_body || '\n\n' || v_start_date || '-' || v_end_date || ': ' || v_description || '\n' || v_url || '\n\n';	
	v_party_to := v_creation_user;

	-- Custom argument might contain user_id different from owner
	-- Notification to HR   	
	if p_custom_arg <> '' THEN
		select into v_name_creation_user im_name_from_id(v_creation_user);
		v_subject := v_subject || ' ' || v_name_creation_user;
		v_party_to := p_custom_arg;	
	END IF;

        RAISE NOTICE 'im_absence_notify_applicant_not_approved: Subject=%, Body=%', v_subject, v_body;

        v_request_id := acs_mail_nt__post_request (
		v_party_from,                 -- party_from
		v_party_to,                   -- party_to
		'f',                          -- expand_group
		v_subject,                    -- subject
		v_body,                       -- message
		0                             -- max_retries
        );
        return 0;
end;$BODY$
  LANGUAGE 'plpgsql' VOLATILE;




CREATE OR REPLACE FUNCTION im_absence_notify_applicant_approved(integer, character varying, character varying)
  RETURNS integer AS
$BODY$
declare
        p_case_id               alias for $1;
        p_transition_key        alias for $2;
	p_custom_arg            alias for $3;

        v_task_id               integer;        v_case_id               integer;
        v_creation_ip           varchar;        v_creation_user         integer;
        v_object_id             integer;        v_object_type           varchar;
        v_journal_id            integer;	v_name_creation_user    varchar;
        v_transition_key        varchar;        v_workflow_key          varchar;
        v_group_id              integer;        v_group_name            varchar;
        v_task_owner            integer;

	v_absence_id		integer;

	v_start_date		text;		 
	v_end_date		text;
	v_description		text;

	v_url			text;
	v_base_url		text;

        v_object_name           text;
        v_party_from            parties.party_id%TYPE;
        v_party_to              parties.party_id%TYPE;
        v_subject               text;
        v_body                  text;
        v_request_id            integer;

        v_locale                text;
        v_count                 integer;

begin
        RAISE NOTICE 'im_absence_notify_applicant_approved: enter - p_case_id=%, p_transition_key=%, p_custom_arg=%', p_case_id, p_transition_key, p_custom_arg;

        -- Select out some frequently used variables of the environment
        select  c.object_id, c.workflow_key, co.creation_user, task_id, c.case_id, co.object_type, co.creation_ip
        into    v_object_id, v_workflow_key, v_creation_user, v_task_id, v_case_id, v_object_type, v_creation_ip
        from    wf_tasks t, wf_cases c, acs_objects co
        where   c.case_id = p_case_id
                and c.case_id = co.object_id
                and t.case_id = c.case_id
                and t.workflow_key = c.workflow_key
                and t.transition_key = p_transition_key;

        v_party_from := -1;

        -- Get locale of user
        select  language_preference into v_locale
        from    user_preferences
        where   user_id = v_creation_user;

        IF v_locale IS NULL THEN
                v_locale := 'en_US';
        END IF;

        -- ------------------------------------------------------------
        -- Try with specific translation first
        v_subject := 'Notification_Subject_Notify_Applicant_Absence_Approved';
        v_subject := acs_lang_lookup_message(v_locale, 'intranet-timesheet2-workflow', v_subject);

        -- Fallback to generic (no transition key) translation
        IF substring(v_subject from 1 for 7) = 'MISSING' THEN
                v_subject := 'Your application for an absence:';
        END IF;

        -- Replace variables
        -- v_subject := replace(v_subject, '%object_name%', v_object_name);
        -- v_subject := replace(v_subject, '%transition_name%', v_transition_name);

        -- ------------------------------------------------------------
        -- Try with specific translation first
        v_body := 'Notification_Body_Notify_Applicant_Absence_Approved';
        v_body := acs_lang_lookup_message(v_locale, 'intranet-timesheet2-workflow', v_body);

        -- Fallback to generic (no transition key) translation
        IF substring(v_body from 1 for 7) = 'MISSING' THEN
                v_body := 'Your application for an absence has been approved';
        END IF;

        -- Replace variables
        -- v_body := replace(v_body, '%object_name%', v_object_name);
        -- v_body := replace(v_body, '%transition_name%', v_transition_name);

	-- get absence_id 
	select object_id into v_absence_id from wf_cases where case_id = p_case_id; 

	-- get URL of absence
	select 	attr_value 
	into 	v_base_url 
	from 
		apm_parameter_values pv,
		apm_parameters p
	where 
		p.package_key = 'acs-kernel' and
		p.parameter_name = 'SystemURL' and 
		pv.parameter_id = p.parameter_id; 

	v_url := v_base_url || 'intranet-timesheet2/absences/new?form_mode=display&absence_id=' || v_absence_id;

        -- get info about absence
        select
                to_char(start_date,'YYYY-MM-DD'),
                to_char(end_date,'YYYY-MM-DD'),
                COALESCE(v_description, '(none)')
        into v_start_date, v_end_date, v_description
        from im_user_absences where absence_id = v_absence_id;

        -- v_body := v_body || '\n\n' || v_description || '\n\n' || v_start_date || '\n\n' || v_end_date || '\n\n' || v_url || '\n\n';
        v_body := v_body || '\n\n' || v_start_date || '-' || v_end_date || ': ' || v_description || '\n' || v_url || '\n\n';
        v_party_to := v_creation_user;

        -- Custom argument might contain user_id different from owner
        -- Notification to HR
        if p_custom_arg <> '' THEN
                select into v_name_creation_user im_name_from_id(v_creation_user);
                v_subject := v_subject || ' ' || v_name_creation_user;
                v_party_to := p_custom_arg;
        END IF;

        RAISE NOTICE 'im_absence_notify_applicant_not_approved: Subject=%, Body=%', v_subject, v_body;

        v_request_id := acs_mail_nt__post_request (
                v_party_from,                 -- party_from
                v_party_to,                   -- party_to
                'f',                          -- expand_group
                v_subject,                    -- subject
                v_body,                       -- message
                0                             -- max_retries
        );
        return 0;
end;$BODY$
  LANGUAGE 'plpgsql' VOLATILE;
-- upgrade-4.0.3.0.1-4.0.3.0.2.sql

SELECT acs_log__debug('/packages/intranet-timesheet2-workflow/sql/postgresql/upgrade/upgrade-4.0.3.0.1-4.0.3.0.2.sql','');

create or replace function inline_0 ()
returns integer as '
declare
        v_count         integer;
begin
        select count(*) into v_count from information_schema.columns where
              table_name = ''im_timesheet_conf_objects''
              and column_name = ''comment'';

        IF v_count > 0 THEN return 1; END IF;

	alter table im_timesheet_conf_objects add column comment text default '''';

        RETURN 0;

end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function im_ts_approval__add_comment(int4,varchar,varchar) returns int4 as '
    declare
            p_case_id               alias for $1;
            p_transition_key        alias for $2;
            p_custom_arg            alias for $3;
    
            v_task_id               integer;        v_case_id               integer;
            v_creation_ip           varchar;        v_user_id               integer;
            v_creation_user         integer;        v_conf_id               integer;
            v_object_id             integer;        v_object_type           varchar;
            v_journal_id            integer;
            v_transition_key        varchar;        v_workflow_key          varchar;
            v_group_id              integer;        v_group_name            varchar;
            v_task_owner            integer;
    
            v_description           text;
            v_msg                   text;
    
            v_object_name           text;
            v_locale                text;
            v_action_pretty         text;
    
    begin
            RAISE NOTICE ''im_ts_approval__add_comment: enter - p_case_id=%, p_transition_key=%, p_custom_arg=%'', p_case_id, p_transition_key, p_custom_arg;
    
            -- Select out some frequently used variables of the environment
            select  c.object_id, c.workflow_key, co.creation_user, task_id, c.case_id, co.object_type, co.creation_ip
            into    v_object_id, v_workflow_key, v_creation_user, v_task_id, v_case_id, v_object_type, v_creation_ip
            from    wf_tasks t, wf_cases c, acs_objects co
            where   c.case_id = p_case_id
                    and c.case_id = co.object_id
                    and t.case_id = c.case_id
                    and t.workflow_key = c.workflow_key
                    and t.transition_key = p_transition_key;
    
    
            -- set object_id
            v_conf_id := v_object_id;
            RAISE NOTICE ''im_ts_approval__add_comment: v_conf_id:% '', v_conf_id;
   
            -- get comment
            v_action_pretty := p_custom_arg || '' finish'';
            select msg into v_msg from journal_entries where object_id = v_case_id and action_pretty = v_action_pretty;
    
            update im_timesheet_conf_objects set comment = v_msg where conf_id = v_conf_id;
    
            return 0;
end;' language 'plpgsql';


create or replace function im_workflow__remove_conf_item_timesheet(int4,text,text) returns int4 as '
         declare
                p_task_id               alias for $1;
                p_custom_arg            alias for $2;
                p_custom_arg_1          alias for $3;
        
                v_transition_key        varchar;
                v_object_type           varchar;
                v_case_id               integer;
                v_object_id             integer;
                v_creation_user         integer;
                v_creation_ip           varchar;
                v_project_manager_id    integer;
                v_project_manager_name  varchar;
        
                v_journal_id            integer;
        
         begin
                RAISE NOTICE ''im_workflow__remove_conf_item_timesheet:alias_1 =%, alias_2 =%, alias3 =%, v_case_id=%'', p_task_id, p_custom_arg, p_custom_arg_1, v_case_id;
                update im_hours set conf_object_id = NULL where conf_object_id in (select object_id from wf_cases where case_id = p_task_id);
                return 0;
end;' language 'plpgsql';

-- upgrade-4.0.3.0.2-4.0.3.0.3.sql

SELECT acs_log__debug('/packages/intranet-timesheet2-workflow/sql/postgresql/upgrade/upgrade-4.0.3.0.2-4.0.3.0.3.sql','');

CREATE OR REPLACE FUNCTION im_absence_notify_applicant_not_approved(integer, character varying, character varying)
  RETURNS integer AS
$BODY$
declare
        p_case_id               alias for $1;
        p_transition_key        alias for $2;
	p_custom_arg            alias for $3;

        v_task_id               integer;        v_case_id               integer;
        v_creation_ip           varchar;        v_creation_user         integer;
        v_object_id             integer;        v_object_type           varchar;
        v_journal_id            integer;        v_name_creation_user    varchar;
        v_transition_key        varchar;        v_workflow_key          varchar;
        v_group_id              integer;        v_group_name            varchar;
        v_task_owner            integer;

	v_absence_id		integer;

	v_start_date		text;		 
	v_end_date		text;
	v_description		text;

	v_url			text;
	v_base_url		text;

        v_object_name           text;
        v_party_from            parties.party_id%TYPE;
        v_party_to              parties.party_id%TYPE;
        v_subject               text;
        v_body                  text;
        v_request_id            integer;

        v_locale                text;
        v_count                 integer;

begin
        RAISE NOTICE 'im_absence_notify_applicant_not_approved: enter - p_case_id=%, p_transition_key=%, p_custom_arg=%', p_case_id, p_transition_key, p_custom_arg;

        -- Select out some frequently used variables of the environment
        select  c.object_id, c.workflow_key, co.creation_user, task_id, c.case_id, co.object_type, co.creation_ip
        into    v_object_id, v_workflow_key, v_creation_user, v_task_id, v_case_id, v_object_type, v_creation_ip
        from    wf_tasks t, wf_cases c, acs_objects co
        where   c.case_id = p_case_id
                and c.case_id = co.object_id
                and t.case_id = c.case_id
                and t.workflow_key = c.workflow_key
                and t.transition_key = p_transition_key;

        v_party_from := -1;

        -- Get locale of user
        select  locale into v_locale
        from    user_preferences
        where   user_id = v_creation_user;

	IF v_locale IS NULL THEN
		v_locale := 'en_US';
	END IF; 

        -- ------------------------------------------------------------
        -- Try with specific translation first
        v_subject := 'Notification_Subject_Notify_Applicant_Absence_Not_Approved';
        v_subject := acs_lang_lookup_message(v_locale, 'intranet-timesheet2', v_subject);

        -- Fallback to generic (no transition key) translation
        IF substring(v_subject from 1 for 7) = 'MISSING' THEN
                v_subject := 'Your application for an absence';
        END IF;

        -- Replace variables
        -- v_subject := replace(v_subject, '%object_name%', v_object_name);
        -- v_subject := replace(v_subject, '%transition_name%', v_transition_name);

        -- ------------------------------------------------------------
        -- Try with specific translation first
        v_body := 'Notification_Body_Notify_Applicant_Absence_Not_Approved';
        v_body := acs_lang_lookup_message(v_locale, 'intranet-timesheet2', v_body);

        -- Fallback to generic (no transition key) translation
        IF substring(v_body from 1 for 7) = 'MISSING' THEN
                v_body := 'Your application for an absence has not been approved:';
        END IF;

        -- Replace variables
        -- v_body := replace(v_body, '%object_name%', v_object_name);
        -- v_body := replace(v_body, '%transition_name%', v_transition_name);

	-- get absence_id 
	select object_id into v_absence_id from wf_cases where case_id = p_case_id; 

	-- get URL of absence
	select 	attr_value 
	into 	v_base_url 
	from 
		apm_parameter_values pv,
		apm_parameters p
	where 
                p.package_key = 'acs-kernel' and
                p.parameter_name = 'SystemURL' and
                pv.parameter_id = p.parameter_id;

	v_url := v_base_url || 'intranet-timesheet2/absences/new?form_mode=display&absence_id=' || v_absence_id;

	-- get info about absence 
       	select
                to_char(start_date,'YYYY-MM-DD'),
                to_char(end_date,'YYYY-MM-DD'),
		COALESCE(v_description, '(none)')
       	into v_start_date, v_end_date, v_description
       	from im_user_absences where absence_id = v_absence_id;

	v_body := v_body || '\n\n' || v_start_date || '-' || v_end_date || ': ' || v_description || '\n' || v_url || '\n\n';	
	v_party_to := v_creation_user;

	-- Custom argument might contain user_id different from owner
	-- Notification to HR   	
	if p_custom_arg <> '' THEN
		select into v_name_creation_user im_name_from_id(v_creation_user);
		v_subject := v_subject || ' ' || v_name_creation_user;
		v_party_to := p_custom_arg;	
	END IF;

        RAISE NOTICE 'im_absence_notify_applicant_not_approved: Subject=%, Body=%', v_subject, v_body;

        v_request_id := acs_mail_nt__post_request (
		v_party_from,                 -- party_from
		v_party_to,                   -- party_to
		'f',                          -- expand_group
		v_subject,                    -- subject
		v_body,                       -- message
		0                             -- max_retries
        );
        return 0;
end;$BODY$
  LANGUAGE 'plpgsql' VOLATILE;




CREATE OR REPLACE FUNCTION im_absence_notify_applicant_approved(integer, character varying, character varying)
  RETURNS integer AS
$BODY$
declare
        p_case_id               alias for $1;
        p_transition_key        alias for $2;
	p_custom_arg            alias for $3;

        v_task_id               integer;        v_case_id               integer;
        v_creation_ip           varchar;        v_creation_user         integer;
        v_object_id             integer;        v_object_type           varchar;
        v_journal_id            integer;	v_name_creation_user    varchar;
        v_transition_key        varchar;        v_workflow_key          varchar;
        v_group_id              integer;        v_group_name            varchar;
        v_task_owner            integer;

	v_absence_id		integer;

	v_start_date		text;		 
	v_end_date		text;
	v_description		text;

	v_url			text;
	v_base_url		text;

        v_object_name           text;
        v_party_from            parties.party_id%TYPE;
        v_party_to              parties.party_id%TYPE;
        v_subject               text;
        v_body                  text;
        v_request_id            integer;

        v_locale                text;
        v_count                 integer;

begin
        RAISE NOTICE 'im_absence_notify_applicant_approved: enter - p_case_id=%, p_transition_key=%, p_custom_arg=%', p_case_id, p_transition_key, p_custom_arg;

        -- Select out some frequently used variables of the environment
        select  c.object_id, c.workflow_key, co.creation_user, task_id, c.case_id, co.object_type, co.creation_ip
        into    v_object_id, v_workflow_key, v_creation_user, v_task_id, v_case_id, v_object_type, v_creation_ip
        from    wf_tasks t, wf_cases c, acs_objects co
        where   c.case_id = p_case_id
                and c.case_id = co.object_id
                and t.case_id = c.case_id
                and t.workflow_key = c.workflow_key
                and t.transition_key = p_transition_key;

        v_party_from := -1;

        -- Get locale of user
        select  locale into v_locale
        from    user_preferences
        where   user_id = v_creation_user;

        IF v_locale IS NULL THEN
                v_locale := 'en_US';
        END IF;

        -- ------------------------------------------------------------
        -- Try with specific translation first
        v_subject := 'Notification_Subject_Notify_Applicant_Absence_Approved';
        v_subject := acs_lang_lookup_message(v_locale, 'intranet-timesheet2', v_subject);

        -- Fallback to generic (no transition key) translation
        IF substring(v_subject from 1 for 7) = 'MISSING' THEN
                v_subject := 'Your application for an absence:';
        END IF;

        -- Replace variables
        -- v_subject := replace(v_subject, '%object_name%', v_object_name);
        -- v_subject := replace(v_subject, '%transition_name%', v_transition_name);

        -- ------------------------------------------------------------
        -- Try with specific translation first
        v_body := 'Notification_Body_Notify_Applicant_Absence_Approved';
        v_body := acs_lang_lookup_message(v_locale, 'intranet-timesheet2', v_body);

        -- Fallback to generic (no transition key) translation
        IF substring(v_body from 1 for 7) = 'MISSING' THEN
                v_body := 'Your application for an absence has been approved';
        END IF;

        -- Replace variables
        -- v_body := replace(v_body, '%object_name%', v_object_name);
        -- v_body := replace(v_body, '%transition_name%', v_transition_name);

	-- get absence_id 
	select object_id into v_absence_id from wf_cases where case_id = p_case_id; 

	-- get URL of absence
	select 	attr_value 
	into 	v_base_url 
	from 
		apm_parameter_values pv,
		apm_parameters p
	where 
		p.package_key = 'acs-kernel' and
		p.parameter_name = 'SystemURL' and 
		pv.parameter_id = p.parameter_id; 

	v_url := v_base_url || 'intranet-timesheet2/absences/new?form_mode=display&absence_id=' || v_absence_id;

        -- get info about absence
        select
                to_char(start_date,'YYYY-MM-DD'),
                to_char(end_date,'YYYY-MM-DD'),
                COALESCE(v_description, '(none)')
        into v_start_date, v_end_date, v_description
        from im_user_absences where absence_id = v_absence_id;

        -- v_body := v_body || '\n\n' || v_description || '\n\n' || v_start_date || '\n\n' || v_end_date || '\n\n' || v_url || '\n\n';
        v_body := v_body || '\n\n' || v_start_date || '-' || v_end_date || ': ' || v_description || '\n' || v_url || '\n\n';
        v_party_to := v_creation_user;

        -- Custom argument might contain user_id different from owner
        -- Notification to HR
        if p_custom_arg <> '' THEN
                select into v_name_creation_user im_name_from_id(v_creation_user);
                v_subject := v_subject || ' ' || v_name_creation_user;
                v_party_to := p_custom_arg;
        END IF;

        RAISE NOTICE 'im_absence_notify_applicant_not_approved: Subject=%, Body=%', v_subject, v_body;

        v_request_id := acs_mail_nt__post_request (
                v_party_from,                 -- party_from
                v_party_to,                   -- party_to
                'f',                          -- expand_group
                v_subject,                    -- subject
                v_body,                       -- message
                0                             -- max_retries
        );
        return 0;
end;$BODY$
  LANGUAGE 'plpgsql' VOLATILE;

-- upgrade-4.0.3.0.3-4.0.3.0.4.sql

-- finally not used, removal of absence causes deletion of wf case which is not desired 
-- maybe useful in the future ... 

SELECT acs_log__debug('/packages/intranet-timesheet2-workflow/sql/postgresql/upgrade/upgrade-4.0.3.0.3-4.0.3.0.4.sql','');

CREATE OR REPLACE FUNCTION im_user_absence_wf__delete(integer, character varying, character varying)
  RETURNS integer AS
$BODY$
declare
        p_case_id               alias for $1;
        p_transition_key        alias for $2;
	p_custom_arg            alias for $3;

        v_task_id               integer;        v_case_id               integer;
        v_creation_ip           varchar;        v_creation_user         integer;
        v_object_id             integer;        v_object_type           varchar;
        v_journal_id            integer;        v_name_creation_user    varchar;
        v_transition_key        varchar;        v_workflow_key          varchar;
        v_group_id              integer;        v_group_name            varchar;
        v_task_owner            integer;

	v_absence_id		integer;
	v_start_date		date;
	v_end_date 		date;
	v_description 		varchar;
	v_absence_type_id 	integer;
	v_absence_name 		varchar;
	v_duration_days		numeric;
begin
        RAISE NOTICE 'im_user_absence_wf__delete: enter - p_case_id=%, p_transition_key=%, p_custom_arg=%', p_case_id, p_transition_key, p_custom_arg;

        -- Select out some frequently used variables of the environment
        select  c.object_id, c.workflow_key, co.creation_user, task_id, c.case_id, co.object_type, co.creation_ip
        into    v_object_id, v_workflow_key, v_creation_user, v_task_id, v_case_id, v_object_type, v_creation_ip
        from    wf_tasks t, wf_cases c, acs_objects co
        where   c.case_id = p_case_id
                and c.case_id = co.object_id
                and t.case_id = c.case_id
                and t.workflow_key = c.workflow_key
                and t.transition_key = p_transition_key;

	-- get absence_id 
	select object_id into v_absence_id from wf_cases where case_id = p_case_id; 
	
	-- Get absence attributes  
	select	start_date, end_date, description, absence_type_id, absence_name, duration_days 
	into 	v_start_date, v_end_date, v_description, v_absence_type_id, v_absence_name, v_duration_days 
	from 	im_user_absences 
	where 	absence_id = v_absence_id; 

	-- remove absence 
	PERFORM im_user_absence__delete(v_absence_id);  

	v_journal_id := journal_entry__new(
	    null, v_case_id, v_transition_key, v_transition_key, now(), v_creation_user, v_creation_ip, 
	    'Removed Absence ID:' || v_absence_id || '(' || 
	    v_start_date || '<br>' || 
	    v_end_date || '<br>' || 
	    v_description || '<br>' || 
	    v_absence_type_id || '<br>' || 
	    v_absence_name || '<br>' || 
	    v_duration_days || ')'    
	);
        return 0;

end;$BODY$
  LANGUAGE 'plpgsql' VOLATILE;



CREATE OR REPLACE FUNCTION im_absences__cleanup()
  RETURNS INTEGER AS
	-- There should be no start_date with '00:00:00 in order to avoid problems with  
	-- constraint im_user_absences::owner_and_start_date_unique UNIQUE, btree (owner_id, absence_type_id, start_date)
        -- Example: Absence WF - Absence has been rejected in the first place, but a new inquiry with same dates and type is made. 
$BODY$

declare
        r                       record;
        v_owner_id              integer;
        v_absence_type_id       integer;
        v_start_date            timestamp;
        v_count        		integer;
	v_interval_str		interval;
	v_counter		integer;
	
begin
        -- Select out some frequently used variables of the environment
        FOR r IN
                select  absence_id, owner_id, absence_type_id, start_date
                from    im_user_absences
                where   absence_status_id = 16002 OR
                        absence_status_id = 16006
                order by owner_id, absence_type_id, start_date
        LOOP
                IF      position('00:00:00' in r.start_date) > 1  THEN
                        RAISE NOTICE 'im_absences__cleanup :: Found absence_id %', absence_id;
			v_counter := 1; 
			FOR i IN 1..300 LOOP				
				v_interval_str := v_counter || ' seconds';
				RAISE NOTICE 'r.start_date: %, v_interval_str: % ', r.start_date, v_interval_str;
				v_start_date := r.start_date::timestamp + v_interval_str;
				select 
					count(*) 
				into 
					v_count            
				from 
					im_user_absences 
				where 
					absence_type_id = r.absence_type_id and 
					owner_id = r.owner_id and
					start_date = v_start_date;

				IF v_count = 0 THEN 
					update im_user_absences set start_date = v_start_date where absence_id = r.absence_id;  
					RAISE NOTICE 'im_absences__cleanup :: Changed absence_id: % to %', r.absence_id, v_start_date;
					EXIT;
				END IF; 
				-- v_interval_str := v_interval_str +1;
			END LOOP;
                END IF;
        END LOOP;
	return 0;
end;$BODY$

LANGUAGE 'plpgsql' VOLATILE;
-- upgrade-4.0.3.0.4-4.0.3.0.5.sql

SELECT acs_log__debug('/packages/intranet-timesheet2-workflow/sql/postgresql/upgrade/upgrade-4.0.3.0.4-4.0.3.0.5.sql','');

CREATE OR REPLACE FUNCTION im_ts_notify_applicant_not_approved(integer, character varying, character varying)
  RETURNS integer AS
$BODY$
declare
        p_case_id               alias for $1;
        p_transition_key        alias for $2;
	p_custom_arg            alias for $3;

        v_task_id               integer;        v_case_id               integer;
        v_creation_ip           varchar;        v_creation_user         integer;
        v_object_id             integer;        v_object_type           varchar;
        v_journal_id            integer;        v_name_creation_user    varchar;
        v_transition_key        varchar;        v_workflow_key          varchar;
        v_group_id              integer;        v_group_name            varchar;
        v_task_owner            integer;

	v_description		text;

	v_project_nr 		text;		v_project_name          text;
	v_project_manager	text;

	v_project_nr_label 	text;		v_project_name_label    text;
	v_project_manager_label	text;
	
	v_url			text;
	v_base_url		text;

        v_object_name           text;
        v_party_from            parties.party_id%TYPE;
        v_party_to              parties.party_id%TYPE;
        v_subject               text;
        v_body                  text;
        v_request_id            integer;

        v_locale                text;
        v_count                 integer;

begin
        RAISE NOTICE 'im_ts_notify_applicant_not_approved: enter - p_case_id=%, p_transition_key=%, p_custom_arg=%', p_case_id, p_transition_key, p_custom_arg;

        -- Select out some frequently used variables of the environment
        select  c.object_id, c.workflow_key, co.creation_user, task_id, c.case_id, co.object_type, co.creation_ip
        into    v_object_id, v_workflow_key, v_creation_user, v_task_id, v_case_id, v_object_type, v_creation_ip
        from    wf_tasks t, wf_cases c, acs_objects co
        where   c.case_id = p_case_id
                and c.case_id = co.object_id
                and t.case_id = c.case_id
                and t.workflow_key = c.workflow_key
                and t.transition_key = p_transition_key;

        v_party_from := -1;

        -- Get locale of user
        select  locale into v_locale
        from    user_preferences
        where   user_id = v_creation_user;

	IF v_locale IS NULL THEN
		v_locale := 'en_US';
	END IF; 

        -- ------------------------------------------------------------
        -- Try with specific translation first
        v_subject := acs_lang_lookup_message(v_locale, 'intranet-timesheet2-workflow', 'Notification_Subject_Notify_Applicant_TS_Not_Approved');

        -- Fallback to generic (no transition key) translation
        IF substring(v_subject from 1 for 7) = 'MISSING' THEN
                v_subject := 'Notification about your Timesheet Approval Workflow';
        END IF;

        -- ------------------------------------------------------------
        -- Try with specific translation first
        v_body := acs_lang_lookup_message(v_locale, 'intranet-timesheet2-workflow','Notification_Body_Notify_Applicant_TS_Not_Approved');
        RAISE NOTICE 'im_ts_notify_applicant_not_approved: Body=%', v_body;

        -- Fallback to generic (no transition key) translation
        IF substring(v_body from 1 for 7) = 'MISSING' THEN
                v_body := 'Your hours logged hours have not been approved:';
        END IF;

        -- get project_name, project_nr und PM 
	select 
		p.project_nr,
		p.project_name,
		im_name_from_id(p.project_lead_id)
	into
		v_project_nr,
		v_project_name,
		v_project_manager 
	from 
		im_projects p, 
		wf_cases c, 
		im_timesheet_conf_objects co
	where 
                c.case_id = p_case_id and
		c.object_id = co.conf_id and  
                co.conf_project_id = p.project_id
	;

	-- get labels 
	v_project_nr_label := acs_lang_lookup_message(v_locale, 'intranet-core', 'Project_Nr');
	v_project_name_label := acs_lang_lookup_message(v_locale, 'intranet-core', 'Project_Name');
	v_project_manager_label := acs_lang_lookup_message(v_locale, 'intranet-core', 'Project_Manager');	
		
	-- get Base URL
	select 	attr_value 
	into 	v_base_url 
	from 
		apm_parameter_values pv,
		apm_parameters p
	where 
                p.package_key = 'acs-kernel' and
                p.parameter_name = 'SystemURL' and
                pv.parameter_id = p.parameter_id;

	v_url := v_base_url || 'acs-workflow/task?return_url=%2fintranet%2f&task_id=' || v_task_id;
	 
	v_body := v_body || '\n\n' || v_project_nr_label || ': ' || v_project_nr || '\n';
	v_body := v_body || v_project_name_label || ': ' || v_project_name || '\n';
	v_body := v_body || v_project_manager_label || ': ' || v_project_manager || '\n\n';
 	v_body := v_body || v_url || '\n\n';	

	v_party_to := v_creation_user;

        v_request_id := acs_mail_nt__post_request (
		v_party_from,                 -- party_from
		v_party_to,                   -- party_to
		'f',                          -- expand_group
		v_subject,                    -- subject
		v_body,                       -- message
		0                             -- max_retries
        );
        return 0;
end;$BODY$
  LANGUAGE 'plpgsql' VOLATILE;



CREATE OR REPLACE FUNCTION im_ts_notify_applicant_approved(integer, character varying, character varying)
  RETURNS integer AS
$BODY$
declare
        p_case_id               alias for $1;
        p_transition_key        alias for $2;
	p_custom_arg            alias for $3;

        v_task_id               integer;        v_case_id               integer;
        v_creation_ip           varchar;        v_creation_user         integer;
        v_object_id             integer;        v_object_type           varchar;
        v_journal_id            integer;        v_name_creation_user    varchar;
        v_transition_key        varchar;        v_workflow_key          varchar;
        v_group_id              integer;        v_group_name            varchar;
        v_task_owner            integer;

	v_description		text;

	v_project_nr 		text;		v_project_name          text;
	v_project_manager	text;

	v_project_nr_label 	text;		v_project_name_label    text;
	v_project_manager_label	text;
	
	v_url			text;
	v_base_url		text;

        v_object_name           text;
        v_party_from            parties.party_id%TYPE;
        v_party_to              parties.party_id%TYPE;
        v_subject               text;
        v_body                  text;
        v_request_id            integer;

        v_locale                text;
        v_count                 integer;

begin
        RAISE NOTICE 'im_ts_notify_applicant_approved: enter - p_case_id=%, p_transition_key=%, p_custom_arg=%', p_case_id, p_transition_key, p_custom_arg;

        -- Select out some frequently used variables of the environment
        select  c.object_id, c.workflow_key, co.creation_user, task_id, c.case_id, co.object_type, co.creation_ip
        into    v_object_id, v_workflow_key, v_creation_user, v_task_id, v_case_id, v_object_type, v_creation_ip
        from    wf_tasks t, wf_cases c, acs_objects co
        where   c.case_id = p_case_id
                and c.case_id = co.object_id
                and t.case_id = c.case_id
                and t.workflow_key = c.workflow_key
                and t.transition_key = p_transition_key;

        v_party_from := -1;

        -- Get locale of user
        select  locale into v_locale
        from    user_preferences
        where   user_id = v_creation_user;

	IF v_locale IS NULL THEN
		v_locale := 'en_US';
	END IF; 

        -- ------------------------------------------------------------
        -- Try with specific translation first
        v_subject := acs_lang_lookup_message(v_locale, 'intranet-timesheet2-workflow', 'Notification_Subject_Notify_Applicant_TS_Approved');

        -- Fallback to generic (no transition key) translation
        IF substring(v_subject from 1 for 7) = 'MISSING' THEN
                v_subject := 'Notification about your Timesheet Approval Workflow';
        END IF;

        -- ------------------------------------------------------------
        -- Try with specific translation first
        v_body := acs_lang_lookup_message(v_locale, 'intranet-timesheet2-workflow','Notification_Body_Notify_Applicant_TS_Approved');

        -- Fallback to generic (no transition key) translation
        IF substring(v_body from 1 for 7) = 'MISSING' THEN
                v_body := 'Your hours logged hours have been approved:';
        END IF;

        -- get project_name, project_nr und PM 
	select 
		p.project_nr,
		p.project_name,
		im_name_from_id(p.project_lead_id)
	into
		v_project_nr,
		v_project_name,
		v_project_manager 
	from 
		im_projects p, 
		wf_cases c, 
		im_timesheet_conf_objects co
	where 
                c.case_id = p_case_id and
		c.object_id = co.conf_id and  
                co.conf_project_id = p.project_id
	;

	-- get labels 
	v_project_nr_label := acs_lang_lookup_message(v_locale, 'intranet-core', 'Project_Nr');
	v_project_name_label := acs_lang_lookup_message(v_locale, 'intranet-core', 'Project_Name');
	v_project_manager_label := acs_lang_lookup_message(v_locale, 'intranet-core', 'Project_Manager');	
		

	-- get Base URL
	select 	attr_value 
	into 	v_base_url 
	from 
		apm_parameter_values pv,
		apm_parameters p
	where 
                p.package_key = 'acs-kernel' and
                p.parameter_name = 'SystemURL' and
                pv.parameter_id = p.parameter_id;

	v_url := v_base_url || 'acs-workflow/task?return_url=%2fintranet%2f&task_id=' || v_task_id;
	 
	v_body := v_body || '\n\n' || v_project_nr_label || ': ' || v_project_nr || '\n';
	v_body := v_body || v_project_name_label || ': ' || v_project_name || '\n';
	v_body := v_body || v_project_manager_label || ': ' || v_project_manager || '\n\n';
 	v_body := v_body || v_url || '\n\n';	

	v_party_to := v_creation_user;

        v_request_id := acs_mail_nt__post_request (
		v_party_from,                 -- party_from
		v_party_to,                   -- party_to
		'f',                          -- expand_group
		v_subject,                    -- subject
		v_body,                       -- message
		0                             -- max_retries
        );
        return 0;
end;$BODY$
  LANGUAGE 'plpgsql' VOLATILE;

