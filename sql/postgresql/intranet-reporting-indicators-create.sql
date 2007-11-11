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


create table im_indicators (
	indicator_id		integer
				constraint im_indicator_id_pk
				primary key
				constraint im_indicator_id_fk
				references im_reports,
	-- Lower widget scale
	indicator_widget_min	double precision,
	-- Upper widget scale
	indicator_widget_max	double precision,
	-- Number of histogram bins between min and max
	indicator_widget_bins	integer
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
	v_name			varchar(2000);
BEGIN
	select	report_name into v_name
	from	im_reports
	where	report_id = p_indicator_id;
	return v_name;
end;' language 'plpgsql';


create or replace function im_indicator__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	varchar, varchar, integer, integer, integer, text,
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
		indicator_id, indicator_name,
		indicator_type_id, indicator_status_id,
		indicator_menu_id, indicator_sql
	) values (
		v_indicator_id, p_indicator_name,
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

