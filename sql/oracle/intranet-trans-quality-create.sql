-- /packages/intranet-trans-quality/sql/oracle/intranet-trans-quality-create.sql
--
-- Copyright (c) 2003-2004 Project/Open
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

create sequence quality_report_id start with 1;
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
	comments		varchar(2000),
				-- redundant fields storing the 
				-- evaluation result so that we can
				-- report on error report rapidly
	allowed_errors		integer,
	total_errors		integer
);
create unique index im_transq_reports_idx on im_trans_quality_reports(task_id);

-- Report entries represent the error counts for the individual
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


delete from categories where category_id >= 7000 and category_id < 7100;


INSERT INTO im_categories (category_id,category,category_type) VALUES
(7002,'Mistranslation','Intranet Translation Quality Type');
INSERT INTO im_categories (category_id,category,category_type) VALUES
(7004,'Accuracy','Intranet Translation Quality Type');
INSERT INTO im_categories (category_id,category,category_type) VALUES
(7006,'Terminology','Intranet Translation Quality Type');
INSERT INTO im_categories (category_id,category,category_type) VALUES
(7008,'Language','Intranet Translation Quality Type');
INSERT INTO im_categories (category_id,category,category_type) VALUES
(7010,'Style','Intranet Translation Quality Type');
INSERT INTO im_categories (category_id,category,category_type) VALUES
(7012,'Country','Intranet Translation Quality Type');
INSERT INTO im_categories (category_id,category,category_type) VALUES
(7014,'Consistency','Intranet Translation Quality Type');




-----------------------------------------------------
-- Sum up translation errors, counting NULL errors as 0:
--

create or replace function im_transq_weighted_error_sum (
	p_task_id IN integer,
	p_project_id IN integer,
	p_minor_errors IN integer,
	p_major_errors IN integer,
	p_critical_errors IN integer
) RETURN number IS
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
END;
/
show errors;




-----------------------------------------------------
-- Components
--

-- Project Quality Component
--
declare
    v_plugin            integer;
begin
    v_plugin := im_component_plugin.new (
        plugin_name =>  'Project Quality Component',
        package_name => 'intranet-trans-quality',
        page_url =>     '/intranet/projects/view',
        location =>     'right',
        sort_order =>   30,
        component_tcl =>
        'im_table_with_title "Quality" [im_quality_project_component \
		-project_id $project_id \
		-return_url $return_url \
	]'
    );
end;
/
show errors



-----------------------------------------------------
-- Defined the view for the list page
--


-- Quality Views
--
insert into im_views (view_id, view_name, visible_for)
values (250, 'quality_list', 'view_quality');


-- Quality List Page
--
delete from im_view_columns where column_id > 25000 and column_id < 25099;
--
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (25001,250,'Task Name',
'"<a href=/intranet-trans-quality/new?task_id=$task_id>$task_name</a>"',1);

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (25003,250,'Source','$source_language',3);

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (25005,250,'Target', '$target_language',5);

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (25007,250,'Units','$task_units',7);

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (25011,250,'Quality', '$expected_quality',11);

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (25013,250,'Report', 
'"<a href=/intranet-trans-quality/new?task_id=$task_id>$total_errors / $allowed_errors</a>"'
,13);

commit;
