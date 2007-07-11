-- upgrade-3.2.11.0.0-3.2.12.0.0.sql

-----------------------------------------------------------
-- Skills Associated with other Objects
--
-- We want to say: For this RFQ you need to translate 
-- from English into Spanish (required condition) and be 
-- preferably specialized in "Legal" or "Business".

create sequence im_object_freelance_skill_seq;

create table im_object_freelance_skill_map (
        object_skill_map_id     integer
                                constraint im_o_skills_pk
                                primary key,
        object_id               integer not null
                                constraint im_o_skills_user_fk
                                references acs_objects,
        skill_id                integer not null
                                constraint im_o_skills_skill_fk
                                references im_categories,
        skill_type_id           integer not null
                                constraint im_o_skills_skill_type_fk
                                references im_categories,
        experience_id           integer
                                constraint im_o_skills_skill_exp_fk
                                references im_categories,
        skill_weight            integer
                                constraint im_o_skills_claimed_ck
                                check (skill_weight > 0 and skill_weight <= 100),
        skill_required_p        char(1) default('f')
                                constraint im_o_skills_required_p
                                check (skill_required_p in ('t','f'))
);

-- Avoid duplicate entries
create unique index im_object_freelance_skill_map_un_idx
on im_object_freelance_skill_map(object_id, skill_type_id, skill_id);

-- Frequent queries per object expected...
create index im_object_freelance_skillsmap_idx
on im_object_freelance_skill_map(object_id);




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

