-- /packages/intranet-freelance/sql/oracle/intranet-freelance-create.sql
--
-- Copyright (c) 2003-2004 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author guillermo.belcic@project-open.com
-- @author frank.bergmann@project-open.com


-----------------------------------------------------------
-- Freelance Management specific data model
--
-- "Freelancers" are a kind of users, exteded by payment
-- methods and a set of skills/tools/...

-----------------------------------------------------------
-- Freelancers
--
-- 
create table im_freelancers (
	user_id			integer
				constraint im_freelancers_pk
				primary key 
				constraint im_freelancers_user_fk
				references users,
	translation_rate	number(6,2),
	editing_rate		number(6,2),
	hourly_rate		number(6,2),
	bank_account		varchar(200),
	bank			varchar(100),
	payment_method_id	integer
				constraint im_freelancers_payment_fk
				references im_categories,
	note			varchar(4000),
	private_note		varchar(4000),
        -- Freelance Recruiting
        rec_source              varchar(400),
        rec_status_id           integer
                                constraint im_freelancers_rec_stat_fk
                                references im_categories,
        rec_test_type           varchar(400),
        rec_test_result_id      integer
                                constraint im_freelancers_rec_test_fk
                                references im_categories
);

-----------------------------------------------------------
-- Skills
--
-- We want to say something like: This user claims he is excellent 
-- at translating into Spanish, but we haven't checked it yet.
-- So what we do is define a mapping between user_ids and 
-- skill_ids. Plus we need to reuse categories such as "Languages"
-- so that we need a "skill type".
-- So we define a "skill type", for example "target languages",
-- or "operating systems". And we define individual skills such
-- as "Castillian Spanish" or "Linux 2.4.x".
--

create table im_freelance_skills (
	user_id			integer not null 
				constraint im_fl_skills_user_fk
				references users,
	skill_id		not null 
				constraint im_fl_skills_skill_fk
				references im_categories,
	skill_type_id		not null 
				constraint im_fl_skills_skill_type_fk
				references im_categories,
	claimed_experience_id	integer
				constraint im_fl_skills_claimed_fk
				references im_categories,
	confirmed_experience_id	integer
				constraint im_fl_skills_conf_fk
				references im_categories,
	confirmation_user_id	integer
				constraint im_fl_skills_conf_user_fk
				references users,
	confirmation_date	date,
	-- "map" type of table
	constraint im_fl_skills_pk
	primary key (user_id, skill_id, skill_type_id)
);

create index im_freelance_skills_user_idx on im_freelance_skills(user_id);


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



-----------------------------------------------------------
-- We need to define this function as a type of "join(..., ", ") to
-- get the list of skills for each user and skill type.
--
-- select im_freelance_skill_list(26,2000) from dual; -> 'es es_LA'
--
create or replace function im_freelance_skill_list ( 
	p_user_id IN number,
	p_skill_type_id IN number) 
RETURN char
IS
	v_skills			varchar(4000);
	v_skill				varchar(4000);

    CURSOR c_user_skills (v_user_id IN number, v_skill_type_id IN number) IS
	select	c.category	
	from	im_freelance_skills s,
		im_categories c
	where  	s.user_id=v_user_id
		and s.skill_type_id=v_skill_type_id
		and s.skill_id=c.category_id
	order by c.category;
BEGIN
	v_skills := '';
	FOR val IN c_user_skills(p_user_id, p_skill_type_id) LOOP
		v_skills := CONCAT(v_skills, ' ');
		v_skills := CONCAT(v_skills, val.category);
	END LOOP;
	RETURN v_skills;
END;
/
show errors;


insert into im_views (view_id, view_name, visible_for) values (50, 'user_list_freelance', '');
insert into im_views (view_id, view_name, visible_for) values (51, 'user_view_freelance', '');
insert into im_views (view_id, view_name, visible_for) values (52, 'freelancers_list', '');




--------------------------------------------------------------
-- FreelancersListPage
--
delete from im_view_columns where column_id >= 5200 and column_id < 5299;

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_from, extra_where, sort_order, visible_for) values (5200,52,NULL,'Name',
'"<a href=/intranet/users/view?user_id=$user_id>$name</a>"',
'f.bank_account, f.bank, f.payment_method_id, f.rec_source, 
f.rec_status_id, f.rec_test_type, f.rec_test_result_id',
'im_freelancers f','u.user_id = f.user_id',0,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (5201,52,NULL,'Email',
'"<a href=mailto:$email>$email</a>"','','',2,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (5203,52,NULL,'MSM',
'"<A HREF=\"http://arkansasmall.tcworks.net:8080/message/msn/$msn_email\">
<IMG SRC=\"http://arkansasmall.tcworks.net:8080/msn/$msn_email\"
width=21 height=22 border=0 ALT=\"MSN Status\"></A>"','','',3,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (5204,52,NULL,'Work Phone',
'$work_phone','','',4,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (5205,52,NULL,'Cell Phone',
'$cell_phone','','',5,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (5206,52,NULL,'Home Phone',
'$home_phone','','',6,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for, order_by_clause) values 
(5208,52,NULL,'Recr Status','$rec_status',
'im_category_from_id(rec_status_id) as rec_status','',8,'','order by rec_status');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for, order_by_clause) values 
(5210,52,NULL,'Recr Test','$rec_test_result',
'im_category_from_id(rec_test_result_id) as rec_test_result','',10,'',
'order by rec_test_result_id');
--
commit;




-- Freelance Skill Types
delete from im_categories where category_id >= 2000 and category_id < 2100;
INSERT INTO im_categories VALUES (2000,'Source Language','Intranet Translation Language','Intranet Skill Type','category','t','f');
INSERT INTO im_categories VALUES (2002,'Target Language','Intranet Translation Language','Intranet Skill Type','category','t','f');
INSERT INTO im_categories VALUES (2004,'Sworn Language','Intranet Translation Language','Intranet Skill Type','category','t','f');
INSERT INTO im_categories VALUES (2006,'TM Tools','Intranet TM Tool','Intranet Skill Type','category','t','f');
INSERT INTO im_categories VALUES (2008,'LOC Tools','Intranet LOC Tool','Intranet Skill Type','category','t','f');
INSERT INTO im_categories VALUES (2010,'Operating System','Intranet Operating System','Intranet Skill Type','category','t','f');
INSERT INTO im_categories VALUES (2014,'Subjects','Intranet Translation Subject Area','Intranet Skill Type','category','t','f');


-- Freelance TM Tools
delete from im_categories where category_id >= 2100 and category_id < 2200;
INSERT INTO im_categories VALUES (2100,'Trados 3.x','','Intranet TM Tool','category','t','f');
INSERT INTO im_categories VALUES (2102,'Trados 5.x','','Intranet TM Tool','category','t','f');
INSERT INTO im_categories VALUES (2104,'Trados 5.5','','Intranet TM Tool','category','t','f');
INSERT INTO im_categories VALUES (2106,'Trados 6.x','','Intranet TM Tool','category','t','f');
INSERT INTO im_categories VALUES (2108,'IBM Translation Workbench','','Intranet TM Tool','category','t','f');


-- Languages experience
delete from im_categories where category_id >= 2200 and category_id < 2300;
INSERT INTO im_categories VALUES (2200, 'Unconfirmed','',
'Intranet Experience Level','category','t','f');
INSERT INTO im_categories VALUES (2201, 'Low','',
'Intranet Experience Level','category','t','f');
INSERT INTO im_categories VALUES (2202, 'Medium','',
'Intranet Experience Level','category','t','f');
INSERT INTO im_categories VALUES (2203, 'High','',
'Intranet Experience Level','category','t','f');


-- Freelance LOC Tools
delete from im_categories where category_id >= 2300 and category_id < 2400;
INSERT INTO im_categories VALUES (2300,'Pasolo ','','Intranet LOC Tool','category','t','f');
INSERT INTO im_categories VALUES (2302,'Catalyst','','Intranet LOC Tool','category','t','f');
-- Operating Systems catgory_id (2350 -> 2399)
INSERT INTO im_categories VALUES (2350,'Windows 98','','Intranet Operating System','category','t','f');
INSERT INTO im_categories VALUES (2351,'Windows NT','','Intranet Operating System','category','t','f');
INSERT INTO im_categories VALUES (2352,'Windows 2000','','Intranet Operating System','category','t','f');
INSERT INTO im_categories VALUES (2353,'Windows XP','','Intranet Operating System','category','t','f');
INSERT INTO im_categories VALUES (2354,'Linux','','Intranet Operating System','category','t','f');


-- ------------------------------------------------------------
-- Definition of Recruiting Categories
-- ------------------------------------------------------------

-- Intranet Recruiting Status
insert into im_categories
( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
values ('', 'f', '6000', 'Potential Freelancer', 'Intranet Recruiting Status');

insert into im_categories
( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
values ('', 'f', '6002', 'Test sent', 'Intranet Recruiting Status');

insert into im_categories
( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
values ('', 'f', '6004', 'Test received', 'Intranet Recruiting Status');

insert into im_categories
( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
values ('', 'f', '6006', 'Test evaluated', 'Intranet Recruiting Status');

commit;



-- Intranet Recruiting Test Results
insert into im_categories
( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
values ('', 'f', '6100', 'A - Test approved', 'Intranet Recruiting Test Result');

insert into im_categories
( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
values ('', 'f', '6102', 'B - No the best...', 'Intranet Recruiting Test Result');

insert into im_categories
( CATEGORY_DESCRIPTION, ENABLED_P, CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
values ('', 'f', '6104', 'C - Test completely failed', 'Intranet Recruiting Test Result');

commit;




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
commit;


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

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (5112,51,NULL,'Trans Rate',
'$translation_rate','','',12,
'im_permission $user_id view_freelancers');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (5114,51,NULL,'Editing Rate',
'$editing_rate','','',14,
'im_permission $user_id view_freelancers');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (5116,51,NULL,'Hourly Rate',
'$hourly_rate','','',16,
'im_permission $user_id view_freelancers');

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

commit;


-- Show the freelance information in users view page
--
declare
    v_plugin            integer;
begin
    v_plugin := im_component_plugin.new (
	plugin_name =>	'Users Freelance Component',
        package_name => 'intranet-freelance',
        page_url =>     '/intranet/users/view',
        location =>     'bottom',
        sort_order =>   10,
        component_tcl =>
        'im_freelance_info_component \
		$current_user_id \
                $user_id \
                $return_url \
		[im_opt_val freelance_view_name]'
    );
end;
/

-- Show the freelance skills in users view page
--
declare
    v_plugin            integer;
begin
    v_plugin := im_component_plugin.new (
	plugin_name =>	'Users Skills Component',
        package_name => 'intranet-freelance',
        page_url =>     '/intranet/users/view',
        location =>     'bottom',
        sort_order =>   20,
        component_tcl =>
        'im_freelance_skill_component \
		$current_user_id \
                $user_id \
                $return_url'
    );
end;
/

-- Show the freelance list in member-add page
--
declare
    v_plugin            integer;
begin
    v_plugin := im_component_plugin.new (
	plugin_name =>	'freelance list Component',
        package_name => 'intranet-freelance',
        page_url =>     '/intranet/member-add',
        location =>     'bottom',
        sort_order =>   10,
        component_tcl =>
        'im_freelance_member_select_component \
		$object_id \
                $return_url'
    );
end;
/
