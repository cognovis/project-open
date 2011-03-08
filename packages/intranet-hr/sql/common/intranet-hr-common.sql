-- /packages/intranet-hr/sql/common/intranet-hr-create.sql
--
-- ]project-open[ HR Module
-- 
-- frank.bergmann@project-open.com, 030828
-- A complete revision of June 1999 by dvr@arsdigita.com
--
-- Copyright (C) 1999-2004 ArsDigita, Frank Bergmann and others
--
-- This program is free software. You can redistribute it 
-- and/or modify it under the terms of the GNU General 
-- Public License as published by the Free Software Foundation; 
-- either version 2 of the License, or (at your option) 
-- any later version. This program is distributed in the 
-- hope that it will be useful, but WITHOUT ANY WARRANTY; 
-- without even the implied warranty of MERCHANTABILITY or 
-- FITNESS FOR A PARTICULAR PURPOSE. 
-- See the GNU General Public License for more details.


-- Employee Pipeline State
delete from im_categories where category_id >= 450 and category_id <= 455;
insert into im_categories (category_id, category, category_type) values 
(450, 'Potential', 'Intranet Employee Pipeline State');
insert into im_categories (category_id, category, category_type) values 
(451, 'Received Test', 'Intranet Employee Pipeline State');
insert into im_categories (category_id, category, category_type) values 
(452, 'Failed Test', 'Intranet Employee Pipeline State');
insert into im_categories (category_id, category, category_type) values 
(453, 'Approved Test', 'Intranet Employee Pipeline State');
insert into im_categories (category_id, category, category_type) values 
(454, 'Active', 'Intranet Employee Pipeline State');
insert into im_categories (category_id, category, category_type) values 
(455, 'Past', 'Intranet Employee Pipeline State');


------------------------------------------------------
-- HR Views
--
create or replace view im_prior_experiences as
select category_id as experience_id, category as experience
from im_categories
where category_type = 'Intranet Prior Experience';

create or replace view im_hiring_sources as
select category_id as source_id, category as source
from im_categories
where category_type = 'Intranet Hiring Source';

create or replace view im_job_titles as
select category_id as job_title_id, category as job_title
from im_categories
where category_type = 'Intranet Job Title';

create or replace view im_qualification_processes as
select category_id as qualification_id, category as qualification
from im_categories
where category_type = 'Intranet Qualification Process';

create or replace view im_employee_pipeline_states as
select category_id as state_id, category as state
from im_categories
where category_type = 'Intranet Employee Pipeline State';



-- 41000-41099  Intranet Salutation (100)

SELECT im_category_new(41000, 'Dear Mr.', 'Intranet Salutation');
SELECT im_category_new(41001, 'Dear Mrs.', 'Intranet Salutation');
SELECT im_category_new(41002, 'Dear Ladies and Gentlemen', 'Intranet Salutation');
SELECT im_category_new(41003, 'Hey Dude', 'Intranet Salutation');



-- prompt *** Creating im_views
insert into im_views (view_id, view_name, visible_for) values (55, 'employees_list', 'view_users');
insert into im_views (view_id, view_name, visible_for) values (56, 'employees_view', 'view_users');




-- prompt *** Creating im_view_columns for employees_list
delete from im_view_columns where view_id = 55;

insert into im_view_columns (column_id, view_id, group_id, column_name, 
column_render_tcl, extra_select, extra_from, extra_where, sort_order, visible_for
) values (5500,55,NULL,'Name',
	'"<a href=/intranet/users/view?user_id=$user_id>$name</a>"',
	'e.supervisor_id, im_name_from_user_id(e.supervisor_id) as supervisor_name',
	'',
	'',
	0,
	''
);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5501,55,'Email','"<a href=mailto:$email>$email</a>"',3);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5502,55,'Supervisor',
'"<a href=/intranet/users/view?user_id=$supervisor_id>$supervisor_name</a>"',3);
-- insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
-- sort_order)values (5502,55,'Status','$status','','',4,'');
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5504,55,'Work Phone','$work_phone',6);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5505,55,'Cell Phone','$cell_phone',7);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5506,55,'Home Phone','$home_phone',8);



-- Employee View
delete from im_view_columns where column_id >= 5600 and column_id < 5699;
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5600,56,'Department',
'"<a href=${department_url}$department_id>$department_name</a>"',0);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5602,56,'Job Title','$job_title',02);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5604,56,'Job Description','$job_description',04);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5606,56,'Availability %','$availability',06);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5607,56,'Hourly Cost','$hourly_cost_formatted',07);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5608,56,'Supervisor',
'"<a href=${user_url}$supervisor_id>$supervisor_name</a>"',08);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5610,56,'Social Security nr','$ss_number',10);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5612,56,'Salary','$salary_formatted',12);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5614,56,'Social Security','$social_security_formatted',14);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5616,56,'Insurance','$insurance_formatted',16);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5618,56,'Other Costs','$other_costs_formatted',18);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5620,56,'Salary Period','$salary_period',20);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5622,56,'Salaries per Year','$salary_payments_per_year',22);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5624,56,'Birthdate','$birthdate_formatted',24);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5626,56,'Start Date','$start_date_formatted',26);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5628,56,'Termination_Date','$end_date_formatted',28);

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5630,56,'Vacation Days per Year','$vacation_days_per_year',30);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5632,56,'Vacation Balance From Last Year','$vacation_balance',32);

