-- upgrade-3.1.10.0.0-3.1.11.0.0.sql

-----------------------------------------------------------
-- Skills Associated with other Objects
--
-- We want to say: For this RFQ you need to translate 
-- from English into Spanish (required condition) and be 
-- preferably specialized in "Legal" or "Business".


create table im_object_freelance_skill_map (
	object_id		integer not null 
				constraint im_o_skills_user_fk
				references acs_objects,
	skill_id		integer not null 
				constraint im_o_skills_skill_fk
				references im_categories,
	skill_type_id		integer not null 
				constraint im_o_skills_skill_type_fk
				references im_categories,
	skill_weight		integer
				constraint im_o_skills_claimed_ck
				check (skill_weight > 0 and skill_weight <= 100),
	skill_required_p	char(1) default('f')
                                constraint im_o_skills_required_p
                                check (skill_required_p in ('t','f')),
	-- "map" type of table
	constraint im_o_skills_pk
	primary key (object_id, skill_id)
);

create index im_object_freelance_skillsmap_idx on im_object_freelance_skill_map(object_id);

