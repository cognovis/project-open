-- /package/intranet-reporting/sql/postgresql/intranet-reporting-create.sql
--
-- Copyright (c) 2003-2005 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author juanjoruizx@yahoo.es

-- Invoices module for Project/Open
--
-- Defines:
--	im_reports		Report biz object container
--

---------------------------------------------------------
-- Reports
--
-- This data model supports the Project/Open reporting tool
-- to generate and store all type of reports.
--
-- Every Report consists of a view that describes the
-- results table and several variables which act as filters
-- over this results.

create table im_reports (
	report_id		integer
				constraint im_reports_pk primary key
				constraint im_reports_id_fk references acs_objects(object_id),
	report_name		varchar(100)
				constraint im_reports_name_un not null unique,
	description		varchar(4000),
	view_id			integer 
				constraint im_reports_view_id_fk references im_views(view_id),
	report_status_id	integer
				constraint im_reports_status_fk
				references im_categories,
	report_type_id		integer
				constraint im_reports_type_fk
				references im_categories
);

create sequence im_report_variables_seq;

create table im_report_variables (
	variable_id		integer
				constraint im_report_variables_pk primary key,
	report_id		integer
				constraint im_report_variables_id_fk references im_reports,
	variable_name		varchar(100)
				constraint im_report_variables_name_un
				not null unique,
	pretty_name		varchar(100),
	widget_name 		varchar(100)
);

---------------------------------------------------------
-- Report Object
---------------------------------------------------------

-- Nothing spectactular, just to be able to use openacs
-- permission system

-- begin

select acs_object_type__create_type (
	'im_report',		-- object_type
	'Report',		-- pretty_name
	'Reports',		-- pretty_plural
	'acs_object',		-- supertype
	'im_reports',		-- table_name
	'report_id',		-- id_column
	'im_report',		-- package_name
	'f',			-- abstract_p
	null,			-- type_extension_table
	'im_report__name'	-- name_method
    );



-- create or replace package body im_report
-- is
create or replace function im_report__new (
	integer,
	varchar,
	timestamptz,
	integer,
	varchar,
	integer,
	varchar,
	integer,
	integer,
	integer,
	varchar
    ) 
returns integer as '
declare
	p_report_id		alias for $1;		-- report_id default null
	p_object_type		alias for $2;		-- object_type default ''im_report''
	p_creation_date		alias for $3;		-- creation_date default now()
	p_creation_user		alias for $4;		-- creation_user
	p_creation_ip		alias for $5;		-- creation_ip default null
	p_context_id		alias for $6;		-- context_id default null
	p_report_name		alias for $7;		-- report_name
	p_view_id		alias for $8;		-- view_id
	p_report_status_id	alias for $9;		-- report_status_id default ???
	p_report_type_id	alias for $10;		-- report_type_id default ???
	p_description		alias for $11;		-- description

	v_report_id		integer;
    begin

	v_report_id := acs_object__new (
                p_report_id,    -- object_id
                p_object_type,  -- object_type
                p_creation_date,        -- creation_date
                p_creation_user,        -- creation_user
                p_creation_ip,  -- creation_ip
                p_context_id    -- context_id
        );
        
        insert into im_reports (
		report_id,
		view_id, 
		report_name,
		description,
		report_status_id,
		report_type_id
	) values (
		v_report_id,
		p_view_id, 
		p_report_name,
		p_description,
		p_report_status_id,
		p_report_type_id
	);

	return v_report_id;
end;' language 'plpgsql';

-- Delete a single report (if we know its ID...)
create or replace function  im_report__delete (integer)
returns integer as '
declare
	p_report_id alias for $1;	-- report_id
begin
	-- Erase the im_report_variables associated with the id
	delete from 	im_report_variables
	where		report_id = p_report_id;

	-- Erase the report itself
	delete from 	im_reports
	where		report_id = p_report_id;
	
	-- Erase all the priviledges
	delete from 	acs_permissions
	where		object_id = p_report_id;
	
	acs_object__delete(p_report_id); 	

	return 0;
end;' language 'plpgsql';

create or replace function im_report__name (integer)
returns varchar as '
declare
	p_report_id alias for $1;	-- report_id
	v_name	varchar(40);
begin
	select	report_name
	into	v_name
	from	im_reports
	where	report_id = p_report_id;

	return v_name;
end;' language 'plpgsql';



---------------------------------------------------------
-- Report Menus
--
-- delete potentially existing menus and plugins if this
-- file is sourced multiple times during development...
-- delete the intranet-payments menus because they are 
-- located below intranet-invoices modules and would
-- cause a RI error.

-- BEGIN
    select im_menu__del_module('intranet-reporting');
-- END;

-- commit;


-- prompt *** Setup the Report main menu entry
--
create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_main_menu 		integer;

	-- Groups
        v_employees             integer;
        v_accounting            integer;
        v_senman                integer;
        v_companies             integer;
        v_freelancers           integer;
        v_proman                integer;
        v_admins                integer;
	v_reg_users		integer;
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
        ''intranet-reporting'', -- package_name
        ''reporting'',          -- label
        ''Reporting'',          -- name
        ''/intranet-reporting/'', -- url
        150,                    -- sort_order
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
    PERFORM acs_permission__grant_permission(v_menu, v_reg_users, ''read'');

    return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();

-- commit;