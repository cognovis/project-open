-----------------------------------------------------------
-- Translation-Quality
--
-- This module is designed to store quality information about
-- the translation process. The basic information is called
-- a "quality report" and determines the the number of
-- {minor|major|critical} errors for a number of error types,
-- defined in the category "Intranet Quality Category".

drop table im_trans_quality_entries;
drop table im_trans_quality_reports;

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
        report_id		integer primary key,
	task_id			references im_tasks,
	report_date		date,
	reviewer_id		references users,
	sample_size		integer,
	allowed_error_percentage number(6,2),
	comments		varchar(200)
);

create unique index im_trans_quality_reports_idx on im_trans_quality_reports(task_id);

-- Report entries represent the error counts for the individual
-- quality categories.
--



create table im_trans_quality_entries (
	report_id		references im_trans_quality_reports,
	quality_category_id	references categories,
	minor_errors		integer,
	major_errors		integer,
	critical_errors		integer,
	primary key (report_id, quality_category_id)
);


delete from categories where category_id >= 2310 and category_id < 2320;


INSERT INTO categories VALUES (2310,'Mistranslation','','Intranet Quality Type',1,'f','');
INSERT INTO categories VALUES (2311,'Accuracy','','Intranet Quality Type',1,'f','');
INSERT INTO categories VALUES (2312,'Terminology','','Intranet Quality Type',1,'f','');
INSERT INTO categories VALUES (2313,'Language','','Intranet Quality Type',1,'f','');
INSERT INTO categories VALUES (2314,'Style','','Intranet Quality Type',1,'f','');
INSERT INTO categories VALUES (2315,'Country','','Intranet Quality Type',1,'f','');
INSERT INTO categories VALUES (2316,'Consistency','','Intranet Quality Type',1,'f','');

