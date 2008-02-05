-- upgrade-3.4.0.0.0-3.4.0.1.0.sql


INSERT INTO im_categories VALUES (2016,'Expected Quality','Intranet Quality','Intranet Skill Type','category','t','f');

-- Show the freelance list in member-add page
--
select im_component_plugin__new (
        null,                           -- plugin_id
        'acs_object',                   -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Freelance Gantt Resource Select Component',    -- plugin_name
        'intranet-freelance',           -- package_name
        'bottom',                       -- location
        '/intranet/member-add',         -- page_url
        null,                           -- view_name
        20,                             -- sort_order
        'im_freelance_gantt_resource_select_component -object_id $object_id -return_url $return_url'
);


-- copy values from im_freelance_skills into im_freelance_object_skill_map
--
insert into im_freelance_object_skill_map (
	object_skill_map_id, object_id, 
	skill_id, skill_type_id, 
	claimed_experience_id, confirmed_experience_id
) select 
	nextval('im_freelance_object_skill_seq'), s.user_id, 
	s.skill_id, s.skill_type_id, 
	s.claimed_experience_id, s.confirmed_experience_id 
from
	im_freelance_skills s
;
