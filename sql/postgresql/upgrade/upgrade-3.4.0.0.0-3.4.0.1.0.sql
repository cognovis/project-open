-- upgrade-3.4.0.0.0-3.4.0.1.0.sql

SELECT acs_log__debug('/packages/intranet-freelance/sql/postgresql/upgrade/upgrade-3.4.0.0.0-3.4.0.1.0.sql','');




SELECT im_category_new (2016, 'Expected Quality','Intranet Skill Type');

create or replace function inline_0 ()
returns integer as '
declare
        v_count                 integer;
begin
        select count(*) into v_count from user_tab_columns
	where lower(table_name) = ''im_object_freelance_skill_map'' and lower(column_name) = ''required_experience_id'';
        if v_count = 0 then 
		alter table im_object_freelance_skill_map
		add required_experience_id integer
		constraint im_fl_skills_requ_fk references im_categories;
	end if;

        select count(*) into v_count from user_tab_columns
	where lower(table_name) = ''im_object_freelance_skill_map'' and lower(column_name) = ''confirmed_experience_id'';
        if v_count = 0 then 
		alter table im_object_freelance_skill_map
		add confirmed_experience_id integer
		constraint im_fl_skills_conf_fk	references im_categories;
	end if;

        select count(*) into v_count from user_tab_columns
	where lower(table_name) = ''im_object_freelance_skill_map'' and lower(column_name) = ''claimed_experience_id'';
        if v_count = 0 then 
		alter table im_object_freelance_skill_map
		add claimed_experience_id integer
		constraint im_fl_skills_claim_fk references im_categories;
	end if;

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



create or replace function inline_0 ()
returns integer as '
declare
        v_count                 integer;
begin
        select count(*) into v_count from pg_class
	where relname = ''im_freelance_object_skill_seq'';
        if v_count > 0 then return 1; end if;

	create sequence im_freelance_object_skill_seq;

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






-- copy values from im_freelance_skills into im_object_freelance_skill_map
--


create or replace function inline_0 ()
returns integer as '
declare
        row		RECORD;
        v_count		integer;
begin
        FOR row IN
		select 
			s.user_id, 
			s.skill_id, 
			s.skill_type_id, 
			s.claimed_experience_id, 
			s.confirmed_experience_id 
		from
			im_freelance_skills s
        LOOP
		select count(*) into v_count from im_object_freelance_skill_map ofsm
		where	ofsm.object_id = row.user_id and
			ofsm.skill_type_id = row.skill_type_id and
			ofsm.skill_id = row.skill_id;

		IF v_count = 0 THEN
			insert into im_object_freelance_skill_map (
				object_skill_map_id, 
				object_id, 
				skill_id, 
				skill_type_id, 
				claimed_experience_id, 
				confirmed_experience_id
			) values (
				nextval(''im_freelance_object_skill_seq''),
				row.user_id,
				row.skill_id,
				row.skill_type_id,
				row.claimed_experience_id,
				row.confirmed_experience_id
			);
		END IF;
        END LOOP;

        RETURN 0;
end;' language 'plpgsql';
select inline_0();
drop function inline_0();

