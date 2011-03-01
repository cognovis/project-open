-- upgrade-3.2.8.0.0-3.3.0.0.0.sql

SELECT acs_log__debug('/packages/intranet-bug-tracker/sql/postgresql/upgrade/upgrade-3.2.8.0.0-3.3.0.0.0.sql','');

create or replace function inline_0 ()
returns integer as '
DECLARE
        v_count                 integer;
BEGIN
        select count(*) into v_count
        from user_tab_columns
        where   lower(table_name) = ''bt_bugs''
                and lower(column_name) = ''bug_container_project_id'';
        IF v_count > 0 THEN return 0; END IF;

	alter table bt_bugs add bug_container_project_id integer references im_projects;

        return 0;
end;' language 'plpgsql';
select inline_0();
drop function inline_0();


