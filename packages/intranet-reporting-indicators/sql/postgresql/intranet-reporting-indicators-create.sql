-- /package/intranet-reporting-indicators/sql/postgresql/intranet-reporting-indicators-create.sql
--
-- Copyright (c) 2003-2007 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com



---------------------------------------------------------
-- Indicators
--
-- Indicators are a special kind of report that returns only 
-- a single numeric value (double precision). This allows for
-- a unified treatment of incidators and displaying them in
-- a timeline on a numeric scale.
--
-- Also, indicators allow to compare a ]po[ company with other
-- companies (benchmarking). In order to do this, indicators
-- values can be exchanged via XML communication.
--
-- Indicator values can be compared within a given subset of
-- reference companies, determined by factors such as sector,
-- company size and geographical region.


SELECT acs_object_type__create_type (
	'im_indicator',			-- object_type
	'Indicator',			-- pretty_name
	'Indicators',			-- pretty_plural
	'im_report',			-- supertype
	'im_indicators',		-- table_name
	'indicator_id',			-- id_column
	'intranet-reporting-indicators', -- package_name
	'f',				-- abstract_p
	null,				-- type_extension_table
	'im_indicator__name'		-- name_method
);

insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_indicator', 'im_indicators', 'indicator_id');
insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_indicator', 'im_reports', 'report_id');


insert into im_biz_object_urls (object_type, url_type, url) values (
'im_indicator','view','/intranet-reporting-indicators/view?indicator_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_indicator','edit','/intranet-reporting-indicators/new?indicator_id=');




create table im_indicators (
	indicator_id		integer
				constraint im_indicator_id_pk
				primary key
				constraint im_indicator_id_fk
				references im_reports,
	indicator_section_id	integer
				constraint im_indicator_section_fk
				references im_categories,
	-- Restrict the indicator to a specific object type?
	-- For example, a holiday_days indicator might be only for users.
	indicator_object_type	varchar(100)
				constraint im_indicator_otype_fk
				references acs_object_types,

	-- Lower widget scale
	indicator_widget_min	double precision,
	-- Upper widget scale
	indicator_widget_max	double precision,
	-- Number of histogram bins between min and max
	indicator_widget_bins	integer,

	-- Indicator colour. Leave empty to disable
	indicator_low_warn	double precision,
	indicator_low_critical	double precision,
	indicator_high_warn	double precision,
	indicator_high_critical	double precision
);



-----------------------------------------------------------
-- Store results of evaluating indicators
--
-- There are two types of results stored in this table:
--	- Individual results: With count=1, for each company and
--	- Cummulative results: With count>1, for aggregated results.

create sequence im_indicator_results_seq;
create table im_indicator_results (
	result_id		integer
				constraint im_indicator_results_pk
				primary key,
	result_indicator_id	integer
				constraint im_indicator_results_indicator_nn
				not null
				constraint im_indicator_results_indicator_fk
				references im_indicators,
	result_date		timestamptz
				constraint im_indicator_results_date_nn
				not null,
				-- The result.
	result			double precision
				constraint im_indicator_results_result_nn
				not null,
				-- Associate a result with a particular object,
				-- for example a user.
	result_object_id	integer
				constraint im_indicator_result_object_fk
				references acs_objects,

				-- How many companies with this result? 
				-- 1 for individual results.
	result_count		integer default 1,
				--
				-- Specification of source of result, 
				-- may be extended in the future
				--
				-- Source systems unique key (anonymous) 
				-- for individual results
	result_system_key	varchar(100),
				-- Sector for cummulative results
	result_sector_id	integer
				constraint im_indicator_results_sector_fk
				references im_categories,
				-- Company size (employees) for cummulative results
	result_company_size	double precision,
				-- Geo region (as a category)
	result_geo_region_id	integer
				constraint im_indicator_results_region_fk
				references im_categories
);


-----------------------------------------------------------
-- Pl/SQL API
--

create or replace function im_indicator__name(integer)
returns varchar as '
DECLARE
	p_indicator_id		alias for $1;
	v_name			varchar;
BEGIN
	select	report_name into v_name
	from	im_reports
	where	report_id = p_indicator_id;
	return v_name;
end;' language 'plpgsql';


create or replace function im_indicator__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	varchar, varchar, integer, integer, text,
	double precision, double precision, integer
) returns integer as '
DECLARE
	p_indicator_id		alias for $1;		-- indicator_id  default null
	p_object_type   	alias for $2;		-- object_type default ''im_indicator''
	p_creation_date 	alias for $3;		-- creation_date default now()
	p_creation_user 	alias for $4;		-- creation_user default null
	p_creation_ip   	alias for $5;		-- creation_ip default null
	p_context_id		alias for $6;		-- context_id default null

	p_indicator_name	alias for $7;		-- indicator_name
	p_indicator_code	alias for $8;
	p_indicator_type_id	alias for $9;		
	p_indicator_status_id	alias for $10;
	p_indicator_sql		alias for $11;

	p_indicator_min		alias for $12;
	p_indicator_max		alias for $13;
	p_indicator_bins	alias for $14;

	v_indicator_id	integer;
BEGIN
	v_indicator_id := acs_object__new (
		p_indicator_id,		-- object_id
		p_object_type,		-- object_type
		p_creation_date,	-- creation_date
		p_creation_user,	-- creation_user
		p_creation_ip,		-- creation_ip
		p_context_id,		-- context_id
		''t''			-- security_inherit_p
	);

	insert into im_reports (
		report_id, report_name, report_code,
		report_type_id, report_status_id,
		report_menu_id, report_sql
	) values (
		v_indicator_id, p_indicator_name, p_indicator_code,
		p_indicator_type_id, p_indicator_status_id,
		null, p_indicator_sql
	);

	insert into im_indicators (
		indicator_id, indicator_widget_min, indicator_widget_max, indicator_widget_bins
	) values (
		v_indicator_id, p_indicator_min, p_indicator_max, p_indicator_bins
	);

	return v_indicator_id;
END;' language 'plpgsql';


create or replace function im_indicator__delete(integer)
returns integer as '
DECLARE
	p_indicator_id	alias for $1;
BEGIN
	-- Delete any results for this indicator
	delete from im_indicator_results
	where	result_indicator_id = p_indicator_id;

	-- Delete any data related to the object
	delete from im_indicators
	where	indicator_id = p_indicator_id;

	-- Reports
	delete from im_reports
	where	report_id = p_indicator_id;

	-- Finally delete the object iself
	PERFORM acs_object__delete(p_indicator_id);

	return 0;
end;' language 'plpgsql';




----------------------------------------------------------
-- Indicator Sections
--
-- These are a hierarchical list of areas in the company

-- 15200-15299  Intranet Indicator Section

select im_category_new (15200, 'Financial Management', 'Intranet Indicator Section');
select im_category_new (15205, 'Customer Management', 'Intranet Indicator Section');
select im_category_new (15210, 'Project Management', 'Intranet Indicator Section');
select im_category_new (15215, 'Timesheet Management', 'Intranet Indicator Section');
select im_category_new (15220, 'Translation Provider Management', 'Intranet Indicator Section');
select im_category_new (15225, 'Translation Project Management', 'Intranet Indicator Section');
select im_category_new (15230, 'Knowledge Management', 'Intranet Indicator Section');
select im_category_new (15235, 'Human Resources Management', 'Intranet Indicator Section');
select im_category_new (15240, 'Other', 'Intranet Indicator Section');
select im_category_new (15245, 'System Usage', 'Intranet Indicator Section');
select im_category_new (15250, 'SLA Management', 'Intranet Indicator Section');
select im_category_new (15255, 'Helpdesk', 'Intranet Indicator Section');


create or replace view im_indicator_sections as
select  category_id as section_id, category as section
from    im_categories
where   category_type = 'Intranet Indicator Section'
        and (enabled_p is null or enabled_p = 't');






---------------------------------------------------------
-- Indicators Menu
--

create or replace function inline_0 ()
returns integer as '
declare
	-- Menu IDs
	v_menu			integer;
	v_main_menu 		integer;

	-- Groups
	v_employees		integer;
	v_accounting		integer;
	v_senman		integer;
	v_customers		integer;
	v_freelancers		integer;
	v_proman		integer;
	v_admins		integer;
	v_reg_users		integer;
BEGIN
	select group_id into v_admins from groups where group_name = ''P/O Admins'';
	select group_id into v_senman from groups where group_name = ''Senior Managers'';
	select group_id into v_proman from groups where group_name = ''Project Managers'';
	select group_id into v_accounting from groups where group_name = ''Accounting'';
	select group_id into v_employees from groups where group_name = ''Employees'';
	select group_id into v_customers from groups where group_name = ''Customers'';
	select group_id into v_freelancers from groups where group_name = ''Freelancers'';
	select group_id into v_reg_users from groups where group_name = ''Registered Users'';

	select menu_id into v_main_menu from im_menus where label=''reporting-other'';

	v_menu := im_menu__new (
		null,					-- p_menu_id
		''acs_object'',				-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creation_ip
		null,					-- context_id
		''intranet-reporting-indicators'',	-- package_name
		''indicators'',				-- label
		''Indicators'',				-- name
		''/intranet-reporting-indicators/index?'', -- url
		160,					-- sort_order
		v_main_menu,				-- parent_menu_id
		null					-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



---------------------------------------------------------
-- Home Page Indicator Component
--

select im_component_plugin__new (
		null,					-- plugin_id
		'acs_object',				-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creattion_ip
		null,					-- context_id
	
		'Home Indicator Component',		-- plugin_name
		'intranet-reporting-indicators',	-- package_name
		'right',				-- location
		'/intranet/index',			-- page_url
		null,					-- view_name
		50,					-- sort_order
		'im_indicator_home_page_component',
		'lang::message::lookup {} intranet-reporting-indicators.Home_Indicator_Component {Home Indicator Component}'
);

select im_grant_permission (
	(select plugin_id from im_component_plugins where plugin_name = 'Home Indicator Component'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);



-- Import some sample indicators
\i intranet-reporting-indicators-crm.sql
\i intranet-reporting-indicators-finance.sql
\i intranet-reporting-indicators-helpdesk.sql
\i intranet-reporting-indicators-hr.sql
\i intranet-reporting-indicators-projects.sql
\i intranet-reporting-indicators-timesheet.sql
\i intranet-reporting-indicators-other.sql

