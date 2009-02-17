-- /packages/intranet-trans-quality/sql/postgresql/intranet-trans-quality-create.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com
-- @author guillermo.belcic@project-open.com

-----------------------------------------------------------
-- Translation-Quality
--
-- This module is designed to store quality information about
-- the translation process. The basic information is called
-- a "quality report" and determines the the number of
-- {minor|major|critical} errors for a number of error types,
-- defined in the category "Intranet Quality Category".

-----------------------------------------------------------
-- Quality Reports
--
-- Represent individual quality reviews, made by a specific
-- person, evaluating a specific task.
--

-- task_id at the beginnig is the primary key but in the future we will
-- study the possibility of make report_id & task_id like primnary keys

create sequence quality_report_id start 1;
create table im_trans_quality_reports (
	report_id		integer 
				constraint im_transq_reports_pk
				primary key,
	task_id			integer
				constraint im_transq_task_fk
				references im_trans_tasks,
	report_date		date,
	reviewer_id		integer
				constraint im_transq_reviewer_fk
				references users,
	sample_size		integer,
	allowed_error_percentage numeric(6,3),
	comments		text,
				-- redundant fields storing the 
				-- evaluation result so that we can
				-- report on error report rapidly
	allowed_errors		integer,
	total_errors		integer
);

create unique index im_transq_reports_idx on im_trans_quality_reports(task_id);


-- Quality report entries represent the error counts for the individual
-- quality categories.
--
create table im_trans_quality_entries (
	report_id		integer
				constraint im_transq_report_fk
				references im_trans_quality_reports,
	quality_category_id	integer
				constraint im_transq_q_category_fk
				references im_categories,
	minor_errors		integer,
	major_errors		integer,
	critical_errors		integer,
	primary key (report_id, quality_category_id)
);


-----------------------------------------------------
-- Sum up translation errors, counting NULL errors as 0:
--
create or replace function im_transq_weighted_error_sum (integer,integer,integer,integer,integer) 
RETURNS integer as '
DECLARE
	p_task_id	alias for $1;
	p_project_id	alias for $2;
	p_minor_errors	alias for $3;
	p_major_errors	alias for $4;
	p_critical_errors alias for $5;

	v_result	integer;
BEGIN
	v_result := 0;

	if p_minor_errors is not null then
		v_result := v_result + p_minor_errors;
	end if;
	if p_major_errors is not null then
		v_result := v_result + p_major_errors * 5;
	end if;
	if p_critical_errors is not null then
		v_result := v_result + p_critical_errors * 10;
	end if;

	return v_result;
END;' language 'plpgsql';


-----------------------------------------------------
-- Components
--

-- Project Quality Component
--
select im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Project Quality Component',	-- plugin_name
	'intranet-trans-quality',	-- package_name
	'right',			-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	10,				-- sort_order
	'im_quality_project_component -project_id $project_id -return_url $return_url'
);




-- -----------------------------------------------------
-- Add privileges for trans_quality
--




create or replace function inline_0 ()
returns integer as '
DECLARE
	v_count		 integer;
BEGIN
	select	count(*) into v_count
	from	acs_privileges
	where	lower(privilege) = ''add_trans_quality'';
	IF v_count > 0 THEN return 0; END IF;

	select acs_privilege__create_privilege(''add_trans_quality'',''Add Trans Quality'',''Add Trans Quality'');
	select acs_privilege__add_child(''admin'', ''add_trans_quality'');
	select acs_privilege__create_privilege(''view_trans_quality'',''View Trans Quality'',''View Trans Quality'');
	select acs_privilege__add_child(''admin'', ''view_trans_quality'');

	return 0;
end;' language 'plpgsql';
select inline_0();
drop function inline_0();






-- Set preliminary privileges to setup the
-- permission matrix

select im_priv_create('view_trans_quality','Accounting');
select im_priv_create('view_trans_quality','P/O Admins');
select im_priv_create('view_trans_quality','Senior Managers');
select im_priv_create('view_trans_quality','Project Managers');
select im_priv_create('view_trans_quality','Accounting');
select im_priv_create('view_trans_quality','Employees');



select im_priv_create('add_trans_quality','P/O Admins');
select im_priv_create('add_trans_quality','Senior Managers');
select im_priv_create('add_trans_quality','Project Managers');
select im_priv_create('add_trans_quality','Accounting');




-- Views and categories common for Oracle and PostgreSQL
\i ../common/intranet-transq-common.sql
