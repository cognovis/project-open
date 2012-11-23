-- /packages/intranet-freelance/sql/common/intranet-freelance-create.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author guillermo.belcic@project-open.com
-- @author frank.bergmann@project-open.com


-----------------------------------------------------------
-- Shortcut view to freelance skills
--
create or replace view im_freelance_skill_types as 
select category_id as skill_type_id, category as skill_type
from im_categories 
where category_type = 'Intranet Skill Type';


-----------------------------------------------------------
-- Menu Modifications
--
-- Let's redirect the "Users" / "Freelancers" menu
-- to the local "index.tcl" page.
update im_menus
set url='/intranet-freelance/index'
where label='users_freelancers';


insert into im_views (view_id, view_name, visible_for) values (
50, 'user_list_freelance', '');
insert into im_views (view_id, view_name, visible_for) values (
51, 'user_view_freelance', '');
insert into im_views (view_id, view_name, visible_for) values (
52, 'freelancers_list', '');



--------------------------------------------------------------
-- FreelancersListPage
--
delete from im_view_columns where column_id >= 5200 and column_id < 5299;

insert into im_view_columns (column_id, view_id, group_id, column_name, 
column_render_tcl, extra_select, extra_from, extra_where, sort_order, 
visible_for) values (5200,52,NULL,'Name',
'"<a href=/intranet/users/view?user_id=$user_id>$name</a>"','','','',0,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, 
column_render_tcl, extra_select, extra_where, sort_order, visible_for) values (
5201,52,NULL,'Email','"<a href=mailto:$email>$email</a>"','','',2,'');

-- insert into im_view_columns (column_id, view_id, group_id, column_name, 
-- column_render_tcl, extra_select, extra_where, sort_order, visible_for) values (
-- 5203,52,NULL,'MSM',
-- '"<A HREF=\"http://arkansasmall.tcworks.net:8080/message/msn/$msn_email\">
-- <IMG SRC=\"http://arkansasmall.tcworks.net:8080/msn/$msn_email\"
-- width=21 height=22 border=0 ALT=\"MSN Status\"></A>"','','',3,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, 
column_render_tcl, extra_select, extra_where, sort_order, visible_for) values (
5204,52,NULL,'Work Phone',
'$work_phone','','',4,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, 
column_render_tcl, extra_select, extra_where, sort_order, visible_for) values (
5205,52,NULL,'Cell Phone','$cell_phone','','',5,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, 
column_render_tcl, extra_select, extra_where, sort_order, visible_for) values (
5206,52,NULL,'Home Phone','$home_phone','','',6,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, 
column_render_tcl, extra_select, extra_where, sort_order, visible_for, order_by_clause) 
values (5208,52,NULL,'Recr Status','$rec_status',
'im_category_from_id(rec_status_id) as rec_status','',8,'','order by rec_status');

insert into im_view_columns (column_id, view_id, group_id, column_name, 
column_render_tcl, extra_select, extra_where, sort_order, visible_for, order_by_clause) 
values (5210,52,NULL,'Recr Test','$rec_test_result',
'im_category_from_id(rec_test_result_id) as rec_test_result','',10,'',
'order by rec_test_result_id');

-- Add a "Score" column to check how freelancer fit with a specific project
-- delete from im_view_columns where column_id=5212;
-- insert into im_view_columns (column_id, view_id, group_id, column_name,
-- column_render_tcl, extra_select, extra_where, sort_order, visible_for, order_by_clause)
-- values (5212,52,NULL,'Score','$score','','',10,'','order by coalesce(s.score, 0) DESC');




-- Freelance Skill Types
-- delete from im_categories where category_id >= 2000 and category_id < 2100;
delete from im_categories where category_type = 'Intranet Skill Type';
INSERT INTO im_categories VALUES (2000,'Source Language','Intranet Translation Language','Intranet Skill Type','category','t','f',null, null, 'Intranet Translation Language');
INSERT INTO im_categories VALUES (2002,'Target Language','Intranet Translation Language','Intranet Skill Type','category','t','f',null, null, 'Intranet Translation Language');
INSERT INTO im_categories VALUES (2004,'Sworn Language','Intranet Translation Language','Intranet Skill Type','category','t','f',null, null, 'Intranet Translation Language');
INSERT INTO im_categories VALUES (2006,'TM Tools','Intranet TM Tool','Intranet Skill Type','category','t','f',null, null, 'Intranet TM Tool');
INSERT INTO im_categories VALUES (2008,'LOC Tools','Intranet LOC Tool','Intranet Skill Type','category','t','f',null, null, 'Intranet LOC Tool');
INSERT INTO im_categories VALUES (2010,'Operating System','Intranet Operating System','Intranet Skill Type','category','t','f',null, null, 'Intranet Operating System');
INSERT INTO im_categories VALUES (2014,'Subjects','Intranet Translation Subject Area','Intranet Skill Type','category','t','f',null, null, 'Intranet Translation Subject Area');
INSERT INTO im_categories VALUES (2016,'Expected Quality','Intranet Quality','Intranet Skill Type','category','t','f',null, null, 'Intranet Quality');

delete from im_categories where category_id in (2020, 2022, 2024, 2026);
INSERT INTO im_categories VALUES (2020,'Software Development',null,'Intranet Skill Type','category','t','f',null, null, 'Intranet Skill Programming Languages');
INSERT INTO im_categories VALUES (2022,'System Admin',null,'Intranet Skill Type','category','t','f',null, null, 'Intranet Skill Operating Systems');
INSERT INTO im_categories VALUES (2024,'Business Sector',null,'Intranet Skill Type','category','t','f',null, null, 'Intranet Skill Business Sector');
INSERT INTO im_categories VALUES (2026,'Consulting Skills',null,'Intranet Skill Type','category','t','f',null, null, 'Intranet Skill Consulting Skills');


-- Category Ranges reservation
-- 80000-89999  Additional skill types, see intranet-freelance-create for details (10000)
-- 80100-80199	Software Development Languages
-- 80200-80299	SysAdmin Skills
-- 80300-80399	Business Sectors
-- 80400-80499	Consulting Skills


delete from im_categories where category_id in (2020, 2022, 2024, 2026);
INSERT INTO im_categories VALUES (2020,'Software Development',null,'Intranet Skill Type','category','t','f',null, null, 'Intranet Skill Programming Language');
INSERT INTO im_categories VALUES (2022,'System Admin',null,'Intranet Skill Type','category','t','f',null, null, 'Intranet Skill SysAdmin Topic');
INSERT INTO im_categories VALUES (2024,'Business Sector',null,'Intranet Skill Type','category','t','f',null, null, 'Intranet Skill Business Sector');
INSERT INTO im_categories VALUES (2026,'Consulting Skills',null,'Intranet Skill Type','category','t','f',null, null, 'Intranet Skill Consulting Skill');

-----------------------------------------------------------
-- 80100-80199  Software Development Languages
--
SELECT im_category_new(80100, 'Abap', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80102, 'Ada', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80104, 'Assembly', 'Intranet Skill Programming Language');
SELECT im_category_new(80106, 'C#', 'Intranet Skill Programming Language');
SELECT im_category_new(80108, 'C', 'Intranet Skill Programming Language');
SELECT im_category_new(80110, 'C++', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80112, 'Cobol', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80114, 'ColdFusion', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80116, 'D', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80118, 'Delphi', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80120, 'Erlang', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80122, 'Forth', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80124, 'Fortran', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80126, 'Haskell', 'Intranet Skill Programming Language');
SELECT im_category_new(80128, 'Java', 'Intranet Skill Programming Language');
SELECT im_category_new(80130, 'JavaScript', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80132, 'Lisp', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80134, 'Lua', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80136, 'OCaml', 'Intranet Skill Programming Language');
SELECT im_category_new(80138, 'Objective C', 'Intranet Skill Programming Language');
SELECT im_category_new(80140, 'PHP', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80142, 'Pascal', 'Intranet Skill Programming Language');
SELECT im_category_new(80144, 'Perl', 'Intranet Skill Programming Language');
SELECT im_category_new(80146, 'Python', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80148, 'Rexx', 'Intranet Skill Programming Language');
SELECT im_category_new(80150, 'Ruby', 'Intranet Skill Programming Language');
SELECT im_category_new(80152, 'SQL', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80154, 'Scala', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80156, 'Scheme', 'Intranet Skill Programming Language');
SELECT im_category_new(80158, 'Shell', 'Intranet Skill Programming Language');
-- SELECT im_category_new(80160, 'Smalltalk', 'Intranet Skill Programming Language');
SELECT im_category_new(80162, 'Tcl', 'Intranet Skill Programming Language');
SELECT im_category_new(80164, 'Visual Basic', 'Intranet Skill Programming Language');


-----------------------------------------------------------
-- 80200-80299  SysAdmin Topics

SELECT im_category_new(80200, 'OS Windows', 'Intranet Skill SysAdmin Topic');
SELECT im_category_new(80205, 'OS Linux', 'Intranet Skill SysAdmin Topic');
SELECT im_category_new(80210, 'OS OS-X', 'Intranet Skill SysAdmin Topic');
SELECT im_category_new(80215, 'OS AIX', 'Intranet Skill SysAdmin Topic');
SELECT im_category_new(80220, 'OS HP-UX', 'Intranet Skill SysAdmin Topic');

SELECT im_category_new(80250, 'DB PostgreSQL', 'Intranet Skill SysAdmin Topic');
SELECT im_category_new(80255, 'DB Oracle', 'Intranet Skill SysAdmin Topic');
SELECT im_category_new(80260, 'DB MS-SQL Server', 'Intranet Skill SysAdmin Topic');
SELECT im_category_new(80265, 'DB DB2', 'Intranet Skill SysAdmin Topic');



-----------------------------------------------------------
-- 80300-80399  Business Sectors

SELECT im_category_new(80300, 'Automotive', 'Intranet Skill Business Sector');
SELECT im_category_new(80305, 'Defense & Aerospace', 'Intranet Skill Business Sector');
SELECT im_category_new(80310, 'Energy & Utilities', 'Intranet Skill Business Sector');
SELECT im_category_new(80315, 'Financial', 'Intranet Skill Business Sector');
SELECT im_category_new(80320, 'ICT & Technology', 'Intranet Skill Business Sector');
SELECT im_category_new(80325, 'Manufacturing', 'Intranet Skill Business Sector');
SELECT im_category_new(80330, 'Pharma & Biotech', 'Intranet Skill Business Sector');
SELECT im_category_new(80335, 'Primary Sector', 'Intranet Skill Business Sector');
SELECT im_category_new(80340, 'Public Sector', 'Intranet Skill Business Sector');
SELECT im_category_new(80345, 'Services', 'Intranet Skill Business Sector');




-----------------------------------------------------------
-- 80400-80499  Consulting Skill

SELECT im_category_new(80400, 'Junior Consultant', 'Intranet Skill Consulting Skill');
SELECT im_category_new(80410, 'Consultant', 'Intranet Skill Consulting Skill');
SELECT im_category_new(80420, 'Senior Consultant', 'Intranet Skill Consulting Skill');
SELECT im_category_new(80430, 'Project Management', 'Intranet Skill Consulting Skill');
SELECT im_category_new(80440, 'Change Management', 'Intranet Skill Consulting Skill');
SELECT im_category_new(80450, 'Process Analysis', 'Intranet Skill Consulting Skill');
SELECT im_category_new(80460, 'User Training', 'Intranet Skill Consulting Skill');
SELECT im_category_new(80470, 'Admin Training', 'Intranet Skill Consulting Skill');








-- Freelance TM Tools
-- delete from im_categories where category_id >= 2100 and category_id < 2200;
delete from im_categories where category_type = 'Intranet TM Tool';
INSERT INTO im_categories VALUES (2100,'Trados 3.x','','Intranet TM Tool','category','t','f');
INSERT INTO im_categories VALUES (2102,'Trados 5.x','','Intranet TM Tool','category','t','f');
INSERT INTO im_categories VALUES (2104,'Trados 5.5','','Intranet TM Tool','category','t','f');
INSERT INTO im_categories VALUES (2106,'Trados 6.x','','Intranet TM Tool','category','t','f');
INSERT INTO im_categories VALUES (2108,'IBM Translation Workbench','','Intranet TM Tool','category','t','f');


-- Languages experience
-- delete from im_categories where category_id >= 2200 and category_id < 2300;
delete from im_categories where category_type = 'Intranet Experience Level';
INSERT INTO im_categories VALUES (2200, 'Unconfirmed','',
'Intranet Experience Level','category','t','f');
INSERT INTO im_categories VALUES (2201, 'Low','',
'Intranet Experience Level','category','t','f');
INSERT INTO im_categories VALUES (2202, 'Medium','',
'Intranet Experience Level','category','t','f');
INSERT INTO im_categories VALUES (2203, 'High','',
'Intranet Experience Level','category','t','f');


-- Freelance LOC Tools
-- delete from im_categories where category_id >= 2300 and category_id < 2400;
delete from im_categories where category_type = 'Intranet LOC Tool';
INSERT INTO im_categories VALUES (2300,'Pasolo ','','Intranet LOC Tool','category','t','f');
INSERT INTO im_categories VALUES (2302,'Catalyst','','Intranet LOC Tool','category','t','f');
-- Operating Systems catgory_id (2350 -> 2399)
delete from im_categories where category_type = 'Intranet Operating System';
INSERT INTO im_categories VALUES (2350,'Windows 98','','Intranet Operating System','category','t','f');
INSERT INTO im_categories VALUES (2351,'Windows NT','','Intranet Operating System','category','t','f');
INSERT INTO im_categories VALUES (2352,'Windows 2000','','Intranet Operating System','category','t','f');
INSERT INTO im_categories VALUES (2353,'Windows XP','','Intranet Operating System','category','t','f');
INSERT INTO im_categories VALUES (2354,'Linux','','Intranet Operating System','category','t','f');


-- ------------------------------------------------------------
-- Definition of Recruiting Categories
-- ------------------------------------------------------------

-- Intranet Recruiting Status
delete from im_categories where category_type = 'Intranet Recruiting Status';
insert into im_categories
( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
values ('', 't', '6000', 'Potential Freelancer', 'Intranet Recruiting Status');

insert into im_categories
( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
values ('', 't', '6002', 'Test sent', 'Intranet Recruiting Status');

insert into im_categories
( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
values ('', 't', '6004', 'Test received', 'Intranet Recruiting Status');

insert into im_categories
( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
values ('', 't', '6006', 'Test evaluated', 'Intranet Recruiting Status');




-- Intranet Recruiting Test Results
delete from im_categories where category_type = 'Intranet Recruiting Test Result';
insert into im_categories
( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
values ('', 't', '6100', 'A - Test approved', 'Intranet Recruiting Test Result');

insert into im_categories
( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
values ('', 't', '6102', 'B - No the best...', 'Intranet Recruiting Test Result');

insert into im_categories
( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
values ('', 't', '6104', 'C - Test completely failed', 'Intranet Recruiting Test Result');




-- Add 'user_list_freelance'
delete from im_view_columns where column_id >= 5000 and column_id < 5099;

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (5000,50,NULL,'Name',
'"<a href=/intranet/users/view?user_id=$user_id>$name</a>"','','',2,
'im_permission $user_id view_freelancers');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (5001,50,NULL,'Email',
'"<a href=mailto:$email>$email</a>"','','',3,
'im_permission $user_id view_freelancers');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (5002,50,NULL,'Status',
'$status','','',4,'im_permission $user_id view_freelancers');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (5003,50,NULL,'Src Lang',
'$source_languages','','',5,'im_permission $user_id view_freelancers');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (5004,50,NULL,'Tgt Lang',
'$target_languages','','',6,'im_permission $user_id view_freelancers');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (5005,50,NULL,'Subj Area',
'$subjects','','',7,'im_permission $user_id view_freelancers');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (5006,50,NULL,'Work Phone',
'$work_phone','','',8,'im_permission $user_id view_freelancers');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (5007,50,NULL,'Cell Phone',
'$cell_phone','','',9,'im_permission $user_id view_freelancers');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (5008,50,NULL,'Home Phone',
'$home_phone','','',10,'im_permission $user_id view_freelancers');


insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (5102,51,NULL,'Recruiting Source',
'$rec_source','','',2,'im_permission $user_id view_freelancers');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (5104,51,NULL,'Recruiting Status',
'$rec_status','','',4,'im_permission $user_id view_freelancers');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (5106,51,NULL,'Recruiting Test Type',
'$rec_test_type','','',6,'im_permission $user_id view_freelancers');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (5108,51,NULL,'Recruiting Test Result',
'$rec_test_result','','',8,'im_permission $user_id view_freelancers');

-- insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
-- extra_select, extra_where, sort_order, visible_for) values (5112,51,NULL,'Trans Rate',
-- '$translation_rate','','',12,
-- 'im_permission $user_id view_freelancers');

-- insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
-- extra_select, extra_where, sort_order, visible_for) values (5114,51,NULL,'Editing Rate',
-- '$editing_rate','','',14,
-- 'im_permission $user_id view_freelancers');

-- insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
-- extra_select, extra_where, sort_order, visible_for) values (5116,51,NULL,'Hourly Rate',
-- '$hourly_rate','','',16,
-- 'im_permission $user_id view_freelancers');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (5118,51,NULL,'Bank Account',
'$bank_account','','',18,
'im_permission $user_id view_freelancers');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (5120,51,NULL,'Bank',
'$bank','','',20,
'im_permission $user_id view_freelancers');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (5132,51,NULL,'Payment Method',
'$payment_method','','',22,
'im_permission $user_id view_freelancers');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (5124,51,NULL,'Note',
'<blockqote>$note</blockquote>','','',24,
'im_permission $user_id view_freelancers');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (5126,51,NULL,'Private Note',
'<blockqote>$private_note</blockquote>','','',26,
'im_permission $user_id view_freelancers');





-- 2400-2419    Intranet Skill Weight

delete from im_categories where category_type = 'Intranet Skill Weight';
INSERT INTO im_categories (category_id, category, category_type, aux_int1)
VALUES (2400, 'Very Important', 'Intranet Skill Weight', 20);

INSERT INTO im_categories (category_id, category, category_type, aux_int1)
VALUES (2402, 'Important', 'Intranet Skill Weight', 10);

INSERT INTO im_categories (category_id, category, category_type, aux_int1)
VALUES (2404, 'Some Importance', 'Intranet Skill Weight', 2);

INSERT INTO im_categories (category_id, category, category_type, aux_int1)
VALUES (2406, 'No Importance', 'Intranet Skill Weight', 0);

INSERT INTO im_categories (category_id, category, category_type, aux_int1)
VALUES (2408, 'Negative Importance (avoid)', 'Intranet Skill Weight', -10);





