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
	private_note		varchar(4000)
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


insert into im_views (view_id, view_name, visible_for) values (50, 'user_list_freelance', 'view_users');
insert into im_views (view_id, view_name, visible_for) values (51, 'user_view_freelance', 'view_users');


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



-- Add 'user_list_freelance'
delete from im_view_columns where column_id >= 5000 and column_id < 5099;

insert into im_view_columns values (5000,50,NULL,'Name',
'"<a href=/intranet/users/view?user_id=$user_id>$name</a>"','','',2,
'im_permission $user_id view_freelancers');
insert into im_view_columns values (5001,50,NULL,'Email',
'"<a href=mailto:$email>$email</a>"','','',3,
'im_permission $user_id view_freelancers');
insert into im_view_columns values (5002,50,NULL,'Status',
'$status','','',4,'im_permission $user_id view_freelancers');
insert into im_view_columns values (5003,50,NULL,'Src Lang',
'$source_languages','','',5,'im_permission $user_id view_freelancers');
insert into im_view_columns values (5004,50,NULL,'Tgt Lang',
'$target_languages','','',6,'im_permission $user_id view_freelancers');
insert into im_view_columns values (5005,50,NULL,'Subj Area',
'$subjects','','',7,'im_permission $user_id view_freelancers');
insert into im_view_columns values (5006,50,NULL,'Work Phone',
'$work_phone','','',8,'im_permission $user_id view_freelancers');
insert into im_view_columns values (5007,50,NULL,'Cell Phone',
'$cell_phone','','',9,'im_permission $user_id view_freelancers');
insert into im_view_columns values (5008,50,NULL,'Home Phone',
'$home_phone','','',10,'im_permission $user_id view_freelancers');
commit;


-- Add 'user_view_freelance'
delete from im_view_columns where column_id >= 5100 and column_id < 5199;

insert into im_view_columns values (5102,51,NULL,'Trans Rate',
'$translation_rate','','',2,
'im_permission $user_id view_freelancers');

insert into im_view_columns values (5104,51,NULL,'Editing Rate',
'$editing_rate','','',4,
'im_permission $user_id view_freelancers');

insert into im_view_columns values (5106,51,NULL,'Hourly Rate',
'$hourly_rate','','',6,
'im_permission $user_id view_freelancers');

insert into im_view_columns values (5108,51,NULL,'Bank Account',
'$bank_account','','',8,
'im_permission $user_id view_freelancers');

insert into im_view_columns values (5110,51,NULL,'Bank',
'$bank','','',10,
'im_permission $user_id view_freelancers');

insert into im_view_columns values (5112,51,NULL,'Payment Method',
'$payment_method','','',12,
'im_permission $user_id view_freelancers');

insert into im_view_columns values (5114,51,NULL,'Note',
'<blockqote>$note</blockquote>','','',14,
'im_permission $user_id view_freelancers');

insert into im_view_columns values (5116,51,NULL,'Private Note',
'<blockqote>$private_note</blockquote>','','',16,
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
