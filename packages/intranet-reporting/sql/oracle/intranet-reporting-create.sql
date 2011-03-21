-- /package/intranet-reporting/sql/oracle/intranet-reporting-create.sql
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
				constraint im_reports_status_fk	references im_categories,
	report_type_id		integer
				constraint im_reports_type_fk references im_categories
);

create sequence im_report_variables_seq;
create im_report_variables (
	variable_id		integer
				constraint im_report_variables_pk primary key,
	report_id		integer
				constraint im_report_variables_id_fk references im_reports,
	variable_name		varchar(100)
				constraint im_report_variables_name_un not null unique,
	pretty_name		varchar(100),
	widget_name 		varchar(100)
);

---------------------------------------------------------
-- Report Object
---------------------------------------------------------

-- Nothing spectactular, just to be able to use openacs
-- permission system

begin
    select acs_object_type__create_type (
	supertype =>		'acs_object',
	object_type =>		'im_report',
	pretty_name =>		'Report',
	pretty_plural =>	'Reports',
	table_name =>		'im_reports',
	id_column =>		'report_id',
	package_name =>		'im_report',
	type_extension_table =>	null,
	name_method =>		'im_report.name'
    );
end;
/
show errors

create or replace package im_report
is
    function new (
	report_id	in integer default null,
	object_type	in varchar default 'im_menu',
	creation_date	in date default sysdate,
	creation_user	in integer default null,
	creation_ip	in varchar default null,
	context_id	in integer default null,
	report_name	in varchar,
	view_id		in integer,
	report_status_id	in integer,
	report_type_id	in integer,
	description	in varchar default null
    ) return im_reports.report_id%TYPE;

    procedure del (report_id in integer);
    function name (report_id in integer) return varchar;
end im_report;
/
show errors


create or replace package body im_report
is
    function new (
	report_id	in integer default null,
	object_type	in varchar default 'im_menu',
	creation_date	in date default sysdate,
	creation_user	in integer default null,
	creation_ip	in varchar default null,
	context_id	in integer default null,
	report_name	in varchar,
	view_id		in integer,
	report_status_id	in integer,
	report_type_id	in integer,
	description	in varchar default null
    ) return im_reports.report_id%TYPE;
    is
    	v_report_id := acs_object__new (
    		object_id =>		report_id,
		object_type =>		object_type,
		creation_date =>	creation_date,
		creation_user =>	creation_user,
		creation_ip =>		creation_ip,
		context_id =>		context_id
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
    		view_id, 
    		report_name,
    		description,
    		report_status_id,
    		report_type_id
    	);
    
	return v_report_id;
    end new;
    
    procedure del (report_id in integer)
    is
	v_report_id	integer;
    begin
	-- copy the variable to desambiguate the var name
	v_report_id := report_id;

	-- Erase the im_report_variables associated with the id
	delete from 	im_report_variables
	where		report_id = v_report_id;
	
	-- Erase the im_reports item associated with the id
	delete from 	im_reports
	where		report_id = v_report_id;

	-- Erase all the priviledges
	delete from 	acs_permissions
	where		object_id = v_report_id;
	
	acs_object.del(v_report_id);    
    end del;
    
    function name (report_id in integer) return varchar
    is
	v_name	im_menus.name%TYPE;
    begin
	-- copy the variable to desambiguate the var name
	v_report_id := report_id;
	
	select	report_name
	into	v_name
	from	im_reports
	where	report_id = v_report_id;

	return v_name;   
    end name;
    
end im_report;
/
show errors



---------------------------------------------------------
-- Report Menus
--
-- delete potentially existing menus and plugins if this
-- file is sourced multiple times during development...
-- delete the intranet-payments menus because they are 
-- located below intranet-invoices modules and would
-- cause a RI error.

BEGIN
    select im_menu__del_module('intranet-reporting');
END;

commit;


prompt *** Setup the Report main menu entry
--
set escape \

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

    select group_id into v_admins from groups where group_name = 'P/O Admins';
    select group_id into v_senman from groups where group_name = 'Senior Managers';
    select group_id into v_proman from groups where group_name = 'Project Managers';
    select group_id into v_accounting from groups where group_name = 'Accounting';
    select group_id into v_employees from groups where group_name = 'Employees';
    select group_id into v_companies from groups where group_name = 'Customers';
    select group_id into v_freelancers from groups where group_name = 'Freelancers';
    select group_id into v_reg_users from groups where group_name = 'Registered Users';


    select menu_id
    into v_main_menu
    from im_menus
    where label='main';

    v_menu := im_menu.new (
    	package_name =>	'intranet-reporting',
    	label =>	'reporting',
    	name =>		'Reporting',
    	url =>		'/intranet-reporting/',
    	sort_order =>	150,
	parent_menu_id => v_main_menu
    );
    
    acs_permission.grant_permission(v_menu, v_admins, 'read');
    acs_permission.grant_permission(v_menu, v_senman, 'read');
    acs_permission.grant_permission(v_menu, v_proman, 'read');
    acs_permission.grant_permission(v_menu, v_accounting, 'read');
    acs_permission.grant_permission(v_menu, v_employees, 'read');
    acs_permission.grant_permission(v_menu, v_companies, 'read');
    acs_permission.grant_permission(v_menu, v_freelancers, 'read');
    acs_permission.grant_permission(v_menu, v_reg_users, 'read');

/
show errors


commit;

