-- upgrade-3.2.9.0.0-3.3.0.0.0.sql

SELECT acs_log__debug('/packages/intranet-freelance/sql/postgresql/upgrade/upgrade-3.2.9.0.0-3.3.0.0.0.sql','');


-----------------------------------------------------------
-- Skills Associated with other Objects
--
-- We want to say: For this RFQ you need to translate 
-- from English into Spanish (required condition) and be 
-- preferably specialized in "Legal" or "Business".



-- Add new fields to files for Files FTS
--
create or replace function inline_0 ()
returns integer as '
declare
	v_count		 integer;
begin
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = ''im_object_freelance_skill_map'';
	IF v_count > 0 THEN return 0; END IF;

	create sequence im_object_freelance_skill_seq;
	create table im_object_freelance_skill_map (
		object_skill_map_id	integer
					constraint im_object_freelance_skills_pk
					primary key,
		object_id		integer not null 
					constraint im_object_freelance_skills_user_fk
					references acs_objects,
		skill_id		integer not null 
					constraint im_object_freelance_skills_skill_fk
					references im_categories,
		skill_type_id		integer not null 
					constraint im_object_freelance_skills_skill_type_fk
					references im_categories,
	
		-- For objects that require skills:
		required_experience_id	integer
					constraint im_object_freelance_skills_skill_exp_fk
					references im_categories,
		skill_weight		integer
					constraint im_object_freelance_skills_claimed_ck
					check (skill_weight > 0 and skill_weight <= 100),
		skill_required_p	char(1) default(''f'')
					constraint im_object_freelance_skills_required_p
					check (skill_required_p in (''t'',''f'')),
	
		-- For objects with these skills:
		claimed_experience_id	integer
					constraint im_fl_skills_claimed_fk
					references im_categories,
		confirmed_experience_id	integer
					constraint im_fl_skills_conf_fk
					references im_categories
	);
	
	-- Avoid duplicate entries
	create unique index im_object_freelance_skill_map_un_idx
	on im_object_freelance_skill_map(object_id, skill_type_id, skill_id);
	
	-- Frequent queries per object expected...
	create index im_object_freelance_skillsmap_idx
	on im_object_freelance_skill_map(object_id);

	return 1;

end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();







create or replace function inline_0 ()
returns integer as '
declare
        v_count                 integer;
begin
        select count(*) into v_count from user_tab_columns
        where lower(table_name) = ''im_object_freelance_skill_map'' and lower(column_name) = ''required_experience_id'';
        if v_count > 0 then return 0; end if;

        alter table im_object_freelance_skill_map
        add required_experience_id integer
        constraint im_fl_skills_required_fk references im_categories;

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



create or replace function inline_0 ()
returns integer as '
declare
        v_count                 integer;
begin
        select count(*) into v_count from user_tab_columns
        where lower(table_name) = ''im_object_freelance_skill_map'' and lower(column_name) = ''claimed_experience_id'';
        if v_count > 0 then return 0; end if;

        alter table im_object_freelance_skill_map
        add claimed_experience_id integer
        constraint im_fl_skills_claimed_fk references im_categories;

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
        v_count                 integer;
begin
        select count(*) into v_count from user_tab_columns
        where lower(table_name) = ''im_object_freelance_skill_map'' and lower(column_name) = ''confirmed_experience_id'';
        if v_count > 0 then return 0; end if;

        alter table im_object_freelance_skill_map
        add confirmed_experience_id integer
        constraint im_fl_skills_conf_fk references im_categories;

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




-- 2400-2419    Intranet Skill Weight

SELECT im_category_new (2400, 'Very Important', 'Intranet Skill Weight');
SELECT im_category_new (2402, 'Important', 'Intranet Skill Weight');
SELECT im_category_new (2404, 'Some Importance', 'Intranet Skill Weight');
SELECT im_category_new (2406, 'No Importance', 'Intranet Skill Weight');
SELECT im_category_new (2408, 'Negative Importance (avoid)', 'Intranet Skill Weight');


update im_categories set aux_int1 = 20 where category_id = 2400;
update im_categories set aux_int1 = 10 where category_id = 2402;
update im_categories set aux_int1 = 20 where category_id = 2404;
update im_categories set aux_int1 = 0 where category_id = 2406;
update im_categories set aux_int1 = -10 where category_id = 2408;


-- Set weights for Languages experience

update im_categories set aux_int1 = 1 where category_id = 2200;
update im_categories set aux_int1 = 2 where category_id = 2201;
update im_categories set aux_int1 = 10 where category_id = 2202;
update im_categories set aux_int1 = 20 where category_id = 2203;





-----------------------------------------------------------
-- Skills Associated with other Objects
--
-- We want to say: For this RFQ you need to translate 
-- from English into Spanish (required condition) and be 
-- preferably specialized in "Legal" or "Business".



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




-- Set weights for Languages experience

update im_categories set aux_int1 = 1 where category_id = 2200;
update im_categories set aux_int1 = 2 where category_id = 2201;
update im_categories set aux_int1 = 10 where category_id = 2202;
update im_categories set aux_int1 = 20 where category_id = 2203;

