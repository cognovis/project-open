-- upgrade-4.0.3.3.7-4.0.3.3.8.sql

SELECT acs_log__debug('/packages/intranet-confdb/sql/postgresql/upgrade/upgrade-4.0.3.3.7-4.0.3.3.8.sql','');


create or replace function inline_0 ()
returns integer as $body$
declare
        v_count         integer;
begin
        -- Sanity check if column exists
        select count(*) into v_count from user_tab_columns
        where lower(table_name) = 'im_conf_items' and lower(column_name) = 'cvs_system';
        IF v_count > 0 THEN return 1; END IF;

	alter table im_conf_items add cvs_system text;

        return 0;
end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


