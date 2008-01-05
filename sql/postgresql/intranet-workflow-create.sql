-- /packages/intranet-workflow/sql/oracle/intranet-workflow-create.sql
--
-- Copyright (c) 2003-2004 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


\i notifications-create.sql

-- ------------------------------------------------------
-- Privileges
-- ------------------------------------------------------

select acs_privilege__create_privilege('wf_reassign_tasks','Reassign tasks to other users','');
select acs_privilege__add_child('admin', 'wf_reassign_tasks');

select im_priv_create('wf_reassign_tasks','Accounting');
select im_priv_create('wf_reassign_tasks','P/O Admins');
select im_priv_create('wf_reassign_tasks','Senior Managers');


-- ------------------------------------------------------
-- Update Project/Task types with Workflow types
-- ------------------------------------------------------

update im_categories
set category_description = 'trans_edit_wf'
where category_id = 87;

update im_categories
set category_description = 'edit_only_wf'
where category_id = 88;

update im_categories
set category_description = 'trans_edit_proof_wf'
where category_id = 89;

update im_categories
set category_description = 'localization_wf'
where category_id = 91;

update im_categories
set category_description = 'trans_only_wf'
where category_id = 93;

update im_categories
set category_description = 'trans_spotcheck_wf'
where category_id = 94;

update im_categories
set category_description = 'proof_only_wf'
where category_id = 95;

update im_categories
set category_description = 'glossary_compilation_wf'
where category_id = 96;



-- ------------------------------------------------------
-- Cleanup
-- ------------------------------------------------------

-- delete potentially existing menus and plugins if this
-- file is sourced multiple times during development...

-- select im_component_plugin__del_module('intranet-workflow');
-- select im_menu__del_module('intranet-workflow');



-- ------------------------------------------------------
-- Components
-- ------------------------------------------------------

-- Show the workflow component in project page
--
SELECT im_component_plugin__new (
        null,                           -- plugin_id
        'acs_object',                   -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Home Workflow Component',      -- plugin_name
        'intranet-workflow',            -- package_name
        'left',                         -- location
        '/intranet/index',              -- page_url
        null,                           -- view_name
        1,                              -- sort_order
	'im_workflow_home_component'
);

-- Project WF Display
--
SELECT im_component_plugin__new (
        null,                           -- plugin_id
        'acs_object',                   -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Project Workflow Graph',       -- plugin_name
        'intranet-workflow',            -- package_name
        'right',                        -- location
        '/intranet/projects/view',     -- page_url
        null,                           -- view_name
        20,                              -- sort_order
        'im_workflow_graph_component -object_id $project_id'
);


-- Project WF Journal
--
SELECT im_component_plugin__new (
        null,                           -- plugin_id
        'acs_object',                   -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Project Workflow Journal',     -- plugin_name
        'intranet-workflow',            -- package_name
        'bottom',                       -- location
        '/intranet/projects/view',      -- page_url
        null,                           -- view_name
        60,                             -- sort_order
        'im_workflow_journal_component -object_id $project_id'
);


-- Home Inbox Component
SELECT  im_component_plugin__new (
	null,					-- plugin_id
	'acs_object',				-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'Home Workflow Inbox',			-- plugin_name
	'intranet-workflow',			-- package_name
	'right',				-- location
	'/intranet/index',			-- page_url
	null,					-- view_name
	150,					-- sort_order
	'im_workflow_home_inbox_component'	-- component_tcl
);





-- ------------------------------------------------------
-- Menus
-- ------------------------------------------------------

create or replace function inline_0 ()
returns integer as '
declare
        -- Menu IDs
        v_menu                  integer;
        v_main_menu             integer;

        -- Groups
        v_employees             integer;
        v_accounting            integer;
        v_senman                integer;
        v_companies             integer;
        v_freelancers           integer;
        v_proman                integer;
        v_admins                integer;
        v_reg_users             integer;
BEGIN
    select group_id into v_admins from groups where group_name = ''P/O Admins'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';
    select group_id into v_proman from groups where group_name = ''Project Managers'';
    select group_id into v_accounting from groups where group_name = ''Accounting'';
    select group_id into v_employees from groups where group_name = ''Employees'';
    select group_id into v_companies from groups where group_name = ''Customers'';
    select group_id into v_freelancers from groups where group_name = ''Freelancers'';
    select group_id into v_reg_users from groups where group_name = ''Registered Users'';

    select menu_id
    into v_main_menu
    from im_menus
    where label=''main'';

    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-workflow'',  -- package_name
        ''workflow'',           -- label
        ''Workflow'',           -- name
        ''/intranet-workflow/'',-- url
        50,                     -- sort_order
        v_main_menu,            -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_companies, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_freelancers, ''read'');

    return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();






-- ------------------------------------------------------
-- Callback functions for Workflow
-- ------------------------------------------------------

-- Set the status of the associated project

create or replace function im_workflow__set_project_status (integer,varchar,text)
returns integer as '
declare
	p_case_id		alias for $1;
	p_transition_key	alias for $2;
	p_custom_arg		alias for $3;

	v_project_id		integer;
	v_project_status_id	integer;
begin
	-- get the project_id
	select	object_id
	into	v_project_id
	from	wf_cases
	where	case_id = p_case_id;

	-- get the project status
	select	project_status_id
	into	v_project_status_id
	from	im_project_status
	where	lower(project_status) = lower(p_custom_arg);

	IF v_project_id is null OR v_project_status_id is null THEN return 0; END IF;

	update	im_projects
	set	project_status_id = v_project_status_id
	where	project_id = v_project_id;

	return 0;
end;' language 'plpgsql';





--------------------------------------------------------------
-- Workflow Views
--
-- Views reserved for workflow: 260-269

delete from im_view_columns where view_id >= 260 and view_id <= 269;
delete from im_views where view_id >= 260 and view_id <= 269;

--------------------------------------------------------------
-- Home Inbox View
insert into im_views (view_id, view_name, visible_for) 
values (260, 'workflow_home_inbox', '');

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl, sort_order) 
values (26000,260,'Action','"<a href=$action_url>$next_action_l10n</a>"',0);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl, sort_order) 
-- values (26010,260,'Object Type','"$object_type_pretty"',10);
-- insert into im_view_columns (column_id, view_id, column_name, column_render_tcl, sort_order) 
values (26020,260,'Type','"$object_subtype"',20);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl, sort_order) 
values (26030,260,'Status','"$status"',30);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl, sort_order) 
values (26040,260,'Object Name','"<a href=$object_url>$object_name</a>"',40);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl, sort_order) 
values (26070,260,'Relationship','"$relationship_l10n"',70);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl, sort_order) 
values (26090,260,
	'<input type=checkbox onclick="acs_ListCheckAll(''action'',this.checked)">',
	'"<input type=checkbox name=task_id value=$task_id id=action,$task_id>"',
90);
