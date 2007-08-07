

-- -----------------------------------------------------
-- Add new project fields to check if it's on track

alter table im_projects add
        percent_completed       float
                                constraint im_project_percent_completed_ck
                                check (percent_completed >= 0 and percent_completed <= 100)
;



alter table im_projects add
        on_track_status_id	integer
                                constraint im_project_on_track_status_id_fk
				references im_categories
;


alter table im_projects add
        project_budget_currency char(3)
                                constraint im_costs_paid_currency_fk
                                references currency_codes(iso)
;

alter table im_projects add
        project_budget_hours    float
;



-- Project On Track Status
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values
('', 'f', '66', 'Green', 'Intranet Project On Track Status');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values
('', 'f', '67', 'Yellow', 'Intranet Project On Track Status');
insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values
('', 'f', '68', 'Red', 'Intranet Project On Track Status');

-- Add the column as the first column to the project view
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2000,20,NULL,'Ok',
'<center>[im_project_on_track_bb $on_track_status_id]</center>',
'','',0,'');



-- Some helper functions to make our queries easier to read
create or replace function im_project_name_from_id (integer)
returns varchar as '
DECLARE
        p_project_id	alias for $1;
        v_project_name	varchar(50);
BEGIN
        select project_name
        into v_project_name
        from im_projects
        where project_id = p_project_id;

        return v_project_name;
end;' language 'plpgsql';



-- Introduce hierarchical project states.
-- Basicly, we've got not three super-states:
--      potential       everything before the project gets "open"
--      open            when the project is executed and
--      close           all possible outcomes when execution is finished
--
insert into im_category_hierarchy values (71,72);
insert into im_category_hierarchy values (71,73);
insert into im_category_hierarchy values (71,74);
insert into im_category_hierarchy values (71,75);
insert into im_category_hierarchy values (81,77);
insert into im_category_hierarchy values (81,78);
insert into im_category_hierarchy values (81,79);
insert into im_category_hierarchy values (81,80);
insert into im_category_hierarchy values (81,82);
insert into im_category_hierarchy values (81,83);



-- Introduce hierarchical company stati
-- Basicly, we've got not three super-states:
--      potential       everything before the company becomes "active"
--      active          when the company is a valid customer or provider
--      close           all possible outcomes when a business relation finishes
--

insert into im_categories ( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE) values
('', 'f', '49', 'Deleted', 'Intranet Company Status');

insert into im_category_hierarchy values (41,42);
insert into im_category_hierarchy values (41,43);
insert into im_category_hierarchy values (41,44);
insert into im_category_hierarchy values (41,45);

insert into im_category_hierarchy values (48,47);
insert into im_category_hierarchy values (48,49);



-- -----------------------------------------------------
-- Companies Menu
-- -----------------------------------------------------

create or replace function inline_1 ()
returns integer as '
declare
      -- Menu IDs
      v_menu                  integer;
      v_companies_menu          integer;

      -- Groups
      v_employees             integer;
      v_accounting            integer;
      v_senman                integer;
      v_customers             integer;
      v_freelancers           integer;
      v_proman                integer;
      v_admins                integer;
begin

    select group_id into v_admins from groups where group_name = ''P/O Admins'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';
    select group_id into v_proman from groups where group_name = ''Project Managers'';
    select group_id into v_accounting from groups where group_name = ''Accounting'';
    select group_id into v_employees from groups where group_name = ''Employees'';
    select group_id into v_customers from groups where group_name = ''Customers'';
    select group_id into v_freelancers from groups where group_name = ''Freelancers'';

    select menu_id
    into v_companies_menu
    from im_menus
    where label=''companies'';

    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''customers_potential'', -- label
        ''Potential Customers'', -- name
        ''/intranet/companies/index?status_id=41&type_id=57'',  -- url
        10,                     -- sort_order
        v_companies_menu,         -- parent_menu_id
        null                    -- p_visible_tcl
    );
    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_customers, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_freelancers, ''read'');


    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''customers_active'',   -- label
        ''Active Customers'',      -- name
        ''/intranet/companies/index?status_id=46&type_id=57'',  -- url
        20,                     -- sort_order
        v_companies_menu,       -- parent_menu_id
        null                    -- p_visible_tcl
    );
    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_customers, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_freelancers, ''read'');



    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''customers_inactive'',   -- label
        ''Inactive Customers'',   -- name
        ''/intranet/companies/index?status_id=48&type_id=57'',  -- url
        30,                     -- sort_order
        v_companies_menu,       -- parent_menu_id
        null                    -- p_visible_tcl
    );
    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_customers, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_freelancers, ''read'');

    return 0;
end;' language 'plpgsql';

select inline_1 ();

drop function inline_1();







-- -----------------------------------------------------
-- Projects Menu (project index page)
-- -----------------------------------------------------

create or replace function inline_1 ()
returns integer as '
declare
      -- Menu IDs
      v_menu                  integer;
      v_projects_menu          integer;

      -- Groups
      v_employees             integer;
      v_accounting            integer;
      v_senman                integer;
      v_customers             integer;
      v_freelancers           integer;
      v_proman                integer;
      v_admins                integer;
begin

    select group_id into v_admins from groups where group_name = ''P/O Admins'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';
    select group_id into v_proman from groups where group_name = ''Project Managers'';
    select group_id into v_accounting from groups where group_name = ''Accounting'';
    select group_id into v_employees from groups where group_name = ''Employees'';
    select group_id into v_customers from groups where group_name = ''Customers'';
    select group_id into v_freelancers from groups where group_name = ''Freelancers'';

    select menu_id
    into v_projects_menu
    from im_menus
    where label=''projects'';

    -- needs to be the first Project menu in order to get selected
    -- The URL should be /intranet/projects/index?view_name=project_list,
    -- but project_list is default in projects/index.tcl, so we can
    -- skip this here.
    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',           -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''projects_potential'',   -- label
        ''Potential'',            -- name
        ''/intranet/projects/index?project_status_id=71'', -- url
        10,                     -- sort_order
        v_projects_menu,         -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_customers, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_freelancers, ''read'');


    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''projects_open'',    -- label
        ''Open'',             -- name
        ''/intranet/projects/index?project_status_id=76'', -- url
        20,                     -- sort_order
        v_projects_menu,         -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_customers, ''read'');


    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''projects_closed'',    -- label
        ''Closed'',             -- name
        ''/intranet/projects/index?project_status_id=81'', -- url
        30,                     -- sort_order
        v_projects_menu,         -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_customers, ''read'');

    return 0;
end;' language 'plpgsql';

select inline_1 ();

drop function inline_1();


