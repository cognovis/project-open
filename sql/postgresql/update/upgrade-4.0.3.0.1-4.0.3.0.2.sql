-- upgrade-4.0.3.0.1-4.0.3.0.2.sql

SELECT acs_log__debug('/packages/intranet-timesheet2-workflow/sql/postgresql/upgrade/upgrade-4.0.3.0.1-4.0.3.0.2.sql','');

create or replace function inline_0 ()
returns integer as '
declare
        v_count         integer;
begin
        select count(*) into v_count from information_schema.columns where
              table_name = ''im_timesheet_conf_objects''
              and column_name = ''comment'';

        IF v_count > 0 THEN return 1; END IF;

	alter table im_timesheet_conf_objects add column comment text;

        RETURN 0;

end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
