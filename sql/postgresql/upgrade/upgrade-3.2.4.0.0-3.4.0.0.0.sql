-- upgrade-3.2.4.0.0-3.4.0.1.0.sql

SELECT acs_log__debug('/packages/intranet-freelance/sql/postgresql/upgrade/upgrade-3.2.4.0.0-3.4.0.0.0.sql','');


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
	constraint im_fl_skills_conf_fk	references im_categories;

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();





