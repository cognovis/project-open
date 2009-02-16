-- /packages/intranet-hr/sql/postgresql/upgrade/upgrade-3.2.3.0.0-3.2.4.0.0.sql

SELECT acs_log__debug('/packages/intranet-hr/sql/postgresql/upgrade/upgrade-3.2.3.0.0-3.2.4.0.0.sql','');


delete from im_view_columns where view_id = 55;
delete from im_view_columns where view_id = 56;

delete from im_views where view_id = 55;
delete from im_views where view_id = 56;

insert into im_views (view_id, view_name, visible_for) values (55, 'employees_list', 'view_users');
insert into im_views (view_id, view_name, visible_for) values (56, 'employees_view', 'view_users');



insert into im_view_columns (column_id, view_id, group_id, column_name, 
column_render_tcl, extra_select, extra_from, extra_where, sort_order, visible_for
) values (5500,55,NULL,'Name',
	'"<a href=/intranet/users/view?user_id=$user_id>$name</a>"',
	'e.supervisor_id, im_name_from_user_id(e.supervisor_id) as supervisor_name',
	'im_employees e',
	'u.user_id = e.employee_id',
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


