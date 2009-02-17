-- upgrade-3.4.0.0.0-3.4.0.1.0.sql

SELECT acs_log__debug('/packages/intranet-freelance/sql/postgresql/upgrade/upgrade-3.4.0.0.0-3.4.0.1.0.sql','');




SELECT im_category_new (2016, 'Expected Quality','Intranet Skill Type');

create or replace function inline_0 ()
returns integer as '
declare
        v_count                 integer;
begin
        select count(*) into v_count from user_tab_columns
	where lower(table_name) = ''im_freelance_object_skill_map'' and lower(column_name) = ''confirmed_experience_id'';
        if v_count > 0 then return 0; end if;

	alter table im_freelance_object_skill_map
	add confirmed_experience_id	integer
	constraint im_fl_skills_conf_fk	references im_categories;

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();





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
