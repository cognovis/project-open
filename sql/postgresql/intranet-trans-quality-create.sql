-- /packages/intranet-trans-quality/sql/postgresql/intranet-trans-quality-create.sql
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
	comments		varchar(2000)
);

create unique index im_transq_reports_idx on im_trans_quality_reports(task_id);


-- /packages/intranet-trans-quality/sql/postgresql/intranet-trans-quality-create.sql
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
	comments		varchar(2000)
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


delete from im_categories where category_id >= 7000 and category_id < 7100;

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

