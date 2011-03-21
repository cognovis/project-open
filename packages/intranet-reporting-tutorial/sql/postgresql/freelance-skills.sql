------------------------------------------------------------
-- Freelance Skills
------------------------------------------------------------

-- Get the list of all Skill Types in the system
select
	st.category_id as skill_type_id,
	st.category as skill_type,
	st.category_description as skill_category
from
	im_categories st
where
	st.category_type = 'Intranet Skill Type'
order by
	st.category_id;


-- Get the skills of a person for a given Skill Type
select
	s.*,
	im_category_from_id(s.skill_id) as skill_name,
	im_category_from_id(s.claimed_experience_id) as claimed_experience,
	im_category_from_id(s.confirmed_experience_id) as confirmed_experience
from
	im_freelance_skills s
where
	user_id = :user_id
	and skill_type_id = :skill_type_id
order by
	s.skill_id;


-- Get the list of all skills for a person
select
	sk.skill_id,
	im_category_from_id(sk.skill_id) as skill,
	c.category_id as skill_type_id,
	im_category_from_id(c.category_id) as skill_type,
	im_category_from_id(sk.claimed_experience_id) as claimed,
	im_category_from_id(sk.confirmed_experience_id) as confirmed,
	sk.claimed_experience_id,
	sk.confirmed_experience_id
from
	(	select c.*
		from im_categories c
		where c.category_type = 'Intranet Skill Type'
		order by c.category_id
	) c
      LEFT JOIN
	(	select *
		from im_freelance_skills
		where user_id = :user_id
		order by skill_type_id
	) sk ON sk.skill_type_id = c.category_id
order by
	c.category_id;


-- Get the list of all skills for a give user in a singe text
-- field. This is useful for list presentations...
--
select im_freelance_skill_list(26,2000) from dual;
-- -> 'es es_LA'


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
	skill_id		integer not null 
				constraint im_fl_skills_skill_fk
				references im_categories,
	skill_type_id		integer not null 
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

