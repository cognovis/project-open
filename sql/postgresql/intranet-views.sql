-- /packages/intranet-core/sql/oracle/intranet-views.sql
--
-- Copyright (C) 2004 Project/Open
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
--
-- @author	guillermo.belcic@project-open.com
-- @author	frank.bergmann@project-open.com
-- @author	juanjoruizx@yahoo.es


-- Defines a number of views to business objects,
-- implementing configurable reports, similar to
-- the choice of columns in the old addressbook.
--
-- fraber@fraber.de, 2003-07-24
--

-- ViewIDs: IDs < 1000 are reserved for Project/Open modules.
--
--  0 -  9	Companies
--  10- 19	Users
--  20- 29	Projects
--  30- 39	Invoices & Payments
--  40- 49	Forum
--  50- 59	Freelance
--  60- 69	Quality
--  70- 79	Marketplace(?)
--  80- 89	Offices
--  90- 99	Translation
-- 100-199	Backup Exports
-- 200-209	Timesheet
-- 210-219	Riskmanagement
-- 220-249	Costs
-- 250-299	Translation Quality

---------------------------------------------------------
-- Views
--
-- Views are a kind of meta-data that determine how a user
-- can see business objects.
-- Every view has:
--	1. Filters - Determine what objects to see
--	2. Columns - Determine how to render columns.
--

create sequence im_views_seq start 1000;
create table im_views (
	view_id			integer 
				constraint im_views_pk
				primary key,
	view_name		varchar(100) 
				constraint im_views_name_un
				not null unique,
	view_type_id		integer
				constraint im_views_type_fk
				references im_categories,
	view_status_id		integer
				constraint im_views_status_fk
				references im_categories,
	visible_for		varchar(1000),
	view_sql		varchar(4000)
);

create sequence im_view_columns_seq start 1000;
create table im_view_columns (
	column_id		integer 
				constraint im_view_columns_pk
				primary key,
	view_id			integer not null 
				constraint im_view_view_id_fk
				references im_views,
	-- group_id=NULL identifies the default view.
	-- however, there may be customized views for a specific group
	group_id		integer
				constraint im_view_columns_group_id_fk
				references groups,
	column_name		varchar(100) not null,
	-- tcl command being executed using "eval" for rendering the column
	column_render_tcl	varchar(4000),
	-- extra SQL components necessary in order to display this
	-- column. All entries without "," or "and".
	extra_select		varchar(4000),
	extra_from		varchar(4000),
	extra_where		varchar(4000),
	-- where to display the column?
	sort_order		integer not null,
	-- how to order the SQL when the "Column Name" is selected?
	order_by_clause		varchar(4000),
	-- set of permission tokens that allow viewing this column,
	-- separated with spaces and OR-joined
	visible_for		varchar(1000)
);


---------------------------------------------------------
-- Standard Views for TCL pages
--
insert into im_views (view_id, view_name, visible_for) values (1, 'company_list', 'view_companies');
insert into im_views (view_id, view_name, visible_for) values (2, 'company_view', 'view_companies');
insert into im_views (view_id, view_name, visible_for) values (10, 'user_list', 'view_users');
insert into im_views (view_id, view_name, visible_for) values (11, 'user_view', 'view_users');
insert into im_views (view_id, view_name, visible_for) values (12, 'user_contact', 'view_users');
insert into im_views (view_id, view_name, visible_for) values (13, 'user_community', 'view_users');
insert into im_views (view_id, view_name, visible_for) values (20, 'project_list', 'view_projects');
insert into im_views (view_id, view_name, visible_for) values (21, 'project_costs', 'view_projects');
insert into im_views (view_id, view_name, visible_for) values (22, 'project_status', 'view_projects');
insert into im_views (view_id, view_name, visible_for) values (80, 'office_list', 'view_offices');
insert into im_views (view_id, view_name, visible_for) values (81, 'office_view', 'view_offices');



--
delete from im_view_columns where column_id > 2200 and column_id < 2299;
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2201,22,NULL,'[_ intranet-core.Project_nr]',
'"<A HREF=/intranet/projects/view?project_id=$project_id>$project_nr</A>"',
'','',1,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2203,22,NULL,'[_ intranet-core.Client]',
'"<A HREF=/intranet/companies/view?company_id=$company_id>$company_name</A>"',
'','',2,'im_permission $user_id view_companies');
-- columns to be here inserted by intranet-timesheet
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2213,22,NULL,'[_ intranet-core.Status]',
'$project_status','','',14,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2215,22,NULL,'[_ intranet-core.Start_Date]',
'$start_date','','',15,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2217,22,NULL,'[_ intranet-core.Delivery_Date]',
'$end_date','','',16,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2219,22,NULL,'[_ intranet-core.Create]',
'$create_date','','',17,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2221,22,NULL,'[_ intranet-core.Quote]',
'$quote_date','','',18,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2223,22,NULL,'[_ intranet-core.Open]',
'$open_date','','',19,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2225,22,NULL,'[_ intranet-core.Deliver]',
'$deliver_date','','',20,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2227,22,NULL,'[_ intranet-core.Invoice]',
'$invoice_date','','',21,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2229,22,NULL,'[_ intranet-core.Close]',
'$close_date','','',22,'');



--
delete from im_view_columns where column_id > 2000 and column_id < 2099;
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2001,20,NULL,'[_ intranet-core.Project_nr]',
'"<A HREF=/intranet/projects/view?project_id=$project_id>$project_nr</A>"',
'','',1,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2003,20,NULL,'[_ intranet-core.Project_Name]',
'"<A HREF=/intranet/projects/view?project_id=$project_id>$project_name</A>"','','',3,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2005,20,NULL,'[_ intranet-core.Client]',
'"<A HREF=/intranet/companies/view?company_id=$company_id>$company_name</A>"',
'','',4,'im_permission $user_id view_companies');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2009,20,NULL,'[_ intranet-core.Type]',
'$project_type','','',5,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2013,20,NULL,'[_ intranet-core.Project_Manager]',
'"<A HREF=/intranet/users/view?user_id=$project_lead_id>$lead_name</A>"',
'','',7,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2015,20,NULL,'[_ intranet-core.Start_Date]',
'$start_date','','',8,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2017,20,NULL,'[_ intranet-core.Delivery_Date]',
'$end_date','','',9,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2021,20,NULL,'[_ intranet-core.Status]',
'$project_status','','',11,'');


--
delete from im_view_columns where column_id > 0 and column_id < 8;
--

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (1,1,NULL,'[_ intranet-core.Client]',
'"<A HREF=$company_view_page?company_id=$company_id>$company_name</A>"','','',1,
'expr 1');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (3,1,NULL,'[_ intranet-core.Type]',
'$company_type','','',2,'expr 1');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (4,1,NULL,'[_ intranet-core.Status]',
'$company_status','','',3,'expr 1');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (5,1,NULL,'[_ intranet-core.Contact]',
'"<A HREF=$user_view_page?user_id=$company_contact_id>$company_contact_name</A>"',
'','',4,'im_permission $user_id view_company_contacts');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (6,1,NULL,'[_ intranet-core.Contact_Email]',
'"<A HREF=mailto:$company_contact_email>$company_contact_email</A>"','','',5,
'im_permission $user_id view_company_contacts');

-- insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
-- extra_select, extra_where, sort_order, visible_for) values (7,1,NULL,'[_ intranet-core.Contact_Phone]',
-- '$company_phone','','',6,'im_permission $user_id view_company_contact');


--------------------------------------------------------------
--
delete from im_view_columns where column_id > 199 and column_id < 299;

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (200,10,NULL,'[_ intranet-core.Name]',
'"<a href=/intranet/users/view?user_id=$user_id>$name</a>"','','',2,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (201,10,NULL,'[_ intranet-core.Email]',
'"<a href=mailto:$email>$email</a>"','','',3,'');

-- insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
-- extra_select, extra_where, sort_order, visible_for) values (202,10,NULL,'[_ intranet-core.Status]',
-- '$status','','',4,'');

--insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
-- extra_select, extra_where, sort_order, visible_for) values (203,10,NULL,'[_ intranet-core.MSM]',
--'"<A HREF=\"http://arkansasmall.tcworks.net:8080/message/msn/$msn_email\"><IMG SRC=\"http://arkansasmall.tcworks.net:8080/msn/$msn_email\" width=21 height=22 border=0 ALT=\"[_ intranet-core.MSN_Status]\"></A>"',
-- '','',5,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (204,10,NULL,'[_ intranet-core.Work_Phone]',
'$work_phone','','',6,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (205,10,NULL,'[_ intranet-core.Cell_Phone]',
'$cell_phone','','',7,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (206,10,NULL,'[_ intranet-core.Home_Phone]',
'$home_phone','','',8,'');



-------------------------------------------------------------------
--
delete from im_view_columns where column_id > 1100 and column_id <= 1199;
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (1101,11,NULL,'[_ intranet-core.Name]','$name','','',1,
'im_view_user_permission $user_id $current_user_id $name view_users');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (1103,11,NULL,'[_ intranet-core.Email]',
'<a href=mailto:$email>$email</a>','','',2,
'im_view_user_permission $user_id $current_user_id $email view_users');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (1105,11,NULL,'[_ intranet-core.Home]',
'<a href=$url>$url</a>','','',3,
'im_view_user_permission $user_id $current_user_id $url view_users');


---------------------------------------------------------------
--
delete from im_view_columns where column_id > 399 and column_id < 499;
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (401,12,NULL,'[_ intranet-core.Home_Phone]','$home_phone','','',1,
'im_view_user_permission $user_id $current_user_id $home_phone view_users');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (403,12,NULL,'[_ intranet-core.Cell_Phone]','$cell_phone','','',2,
'im_view_user_permission $user_id $current_user_id $cell_phone view_users');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (404,12,NULL,'[_ intranet-core.Work_Phone]','$work_phone','','',3,
'im_view_user_permission $user_id $current_user_id $work_phone view_users');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (405,12,NULL,'[_ intranet-core.Pager]','$pager','','',4,
'im_view_user_permission $user_id $current_user_id $pager view_users');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (407,12,NULL,'[_ intranet-core.Fax]','$fax','','',5,
'im_view_user_permission $user_id $current_user_id $fax view_users');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (409,12,NULL,'[_ intranet-core.AIM]','$aim_screen_name','','',6,
'im_view_user_permission $user_id $current_user_id $aim_screen_name view_users');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (411,12,NULL,'[_ intranet-core.ICQ]','$icq_number','','',7,
'im_view_user_permission $user_id $current_user_id $icq_number view_users');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (413,12,NULL,'[_ intranet-core.Home_Line_1]','$ha_line1','','',8,
'im_view_user_permission $user_id $current_user_id $ha_line1 view_users');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (415,12,NULL,'[_ intranet-core.Home_Line_2]','$ha_line2','','',9,
'im_view_user_permission $user_id $current_user_id $ha_line2 view_users');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (417,12,NULL,'[_ intranet-core.Home_City]','$ha_city','','',10,
'im_view_user_permission $user_id $current_user_id $ha_city view_users');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (421,12,NULL,'[_ intranet-core.Home_ZIP]','$ha_postal_code','','',11,
'im_view_user_permission $user_id $current_user_id $ha_postal_code view_users');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (423,12,NULL,'[_ intranet-core.Home_Country]','$ha_country_name','','',
12,'im_view_user_permission $user_id $current_user_id $ha_country_name view_users');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (425,12,NULL,'[_ intranet-core.Work_Line_1]','$wa_line1','','',13,
'im_view_user_permission $user_id $current_user_id $wa_line1 view_users');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (427,12,NULL,'[_ intranet-core.Work_Line_2]','$wa_line2','','',14,
'im_view_user_permission $user_id $current_user_id $wa_line2 view_users');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (429,12,NULL,'[_ intranet-core.Work_City]','$wa_city','','',15,
'im_view_user_permission $user_id $current_user_id $wa_city view_users');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (433,12,NULL,'[_ intranet-core.Work_ZIP]','$wa_postal_code','','',16,
'im_view_user_permission $user_id $current_user_id $wa_postal_code view_users');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (435,12,NULL,'[_ intranet-core.Work_Country]','$wa_country_name','','',
17,'im_view_user_permission $user_id $current_user_id $wa_country_name view_users');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (437,12,NULL,'[_ intranet-core.Note]','$note','','',18,
'im_view_user_permission $user_id $current_user_id $note view_users');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (439,12,NULL,' ',
'"<input type=submit value=Edit>"','','',99,
'set a $write');



-------------------------------------------------------------------
-- Unassigned Users View
--
delete from im_view_columns where column_id > 1300 and column_id <= 1399;
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (1310,13,NULL,'[_ intranet-core.Creation]',
'$creation_date','','',10,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (1315,13,NULL,'[_ intranet-core.Last_Visit]',
'$last_visit','','',15,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (1320,13,NULL,'[_ intranet-core.Name]',
'<a href=$user_view_page?user_id=$user_id>$name</a>','','',20,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (1330,13,NULL,'[_ intranet-core.Email]',
'<a href=mailto:$email>$email</a>','','',30,'');






----------------------------------------------------------------
-- Offices
--

--
delete from im_view_columns where column_id >= 8000 and column_id <= 8099;
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8001,80,NULL,'[_ intranet-core.Office]',
'"<A HREF=$office_view_page?office_id=$office_id>$office_name</A>"','','',10,
'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8002,80,NULL,'[_ intranet-core.Company]',
'"<A HREF=$company_view_page?company_id=$company_id>$company_name</A>"','','',20,
'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8003,80,NULL,'[_ intranet-core.Type]',
'$office_type','','',30,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8004,80,NULL,'[_ intranet-core.Status]',
'$office_status','','',40,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8005,80,NULL,'[_ intranet-core.Contact]',
'"<A HREF=$user_view_page?user_id=$contact_person_id>$contact_person_name</A>"',
'','',50,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8006,80,NULL,'[_ intranet-core.City]',
'$address_city','','',60,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8007,80,NULL,'[_ intranet-core.Phone]',
'$phone','','',70,'');



--
delete from im_view_columns where column_id >= 8100 and column_id <= 8199;
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8100,81,NULL,'[_ intranet-core.Office_Name]','$office_name','','',
10, '');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8101,81,NULL,'[_ intranet-core.Office_Path]','$office_path','','',
15, '');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8102,81,NULL,'[_ intranet-core.Company]',
'"<A HREF=$company_view_page?company_id=$company_id>$company_name</A>"','','',
20, 'im_permission $user_id view_companies');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8104,81,NULL,'[_ intranet-core.Type]', '$office_type','','',
40,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8106,81,NULL,'[_ intranet-core.Status]','$office_status','','',
60,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8108,81,NULL,'[_ intranet-core.Contact]',
'"<A HREF=$user_view_page?user_id=$contact_person_id>$contact_person_name</A>"','','',
80,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8130,81,NULL,'[_ intranet-core.Phone]','$phone','','',
300,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8132,81,NULL,'[_ intranet-core.Fax]','$fax','','',
320,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8150,81,NULL,'[_ intranet-core.City]','$address_city','','',
500,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8152,81,NULL,'[_ intranet-core.State]','$address_state','','',
520,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8154,81,NULL,'[_ intranet-core.Country]','$address_country','','',
540,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8156,81,NULL,'[_ intranet-core.ZIP]','$address_postal_code','','',
560,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8158,81,NULL,'[_ intranet-core.Address]',
'$address_line1 $address_line2','','',
580,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8170,81,NULL,'[_ intranet-core.Note]','$note','','',
700,'');

--
delete from im_view_columns where column_id >= 8190 and column_id <= 8199;
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8190,81,NULL,' ','"<input type=submit value=Edit>"','','',
900,'set a $admin');

--
