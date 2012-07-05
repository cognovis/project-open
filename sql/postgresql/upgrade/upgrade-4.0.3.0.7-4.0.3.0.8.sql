-- upgrade-4.0.3.0.6-4.0.3.0.7.sql
SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-4.0.3.0.6-4.0.3.0.7.sql','');


create or replace function inline_0 ()
returns integer as $body$
declare
        v_count  integer;
begin
        select count(*) into v_count from user_tab_columns
        where lower(table_name) = 'im_biz_object_members' and lower(column_name) = 'skill_profile_rel_id';
        IF v_count = 0 THEN
                alter table im_biz_object_members
		add column skill_profile_rel_id integer
		constraint im_biz_object_members_skill_profile_rel_fk
		references im_biz_object_members;
        END IF;

        return 0;
end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

