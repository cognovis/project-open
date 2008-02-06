-- upgrade-3.2.4.0.0-3.4.0.1.0.sql

alter table im_freelance_object_skill_map
add claimed_experience_id	integer
constraint im_fl_skills_claimed_fk references im_categories;


alter table im_freelance_object_skill_map
add confirmed_experience_id	integer
constraint im_fl_skills_conf_fk	references im_categories;
