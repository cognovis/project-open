-- upgrade-3.4.0.8.9-3.4.1.0.0.sql

SELECT acs_log__debug('/packages/intranet-timesheet2/sql/postgresql/upgrade/upgrade-3.4.0.8.9-3.4.1.0.0.sql','');


-- Adding a fake object_id "hour_id" with an default
-- to take the value automatically from a sequence.
--
create or replace function inline_0 ()
returns integer as $body$
declare
        v_count                 integer;
begin
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = 'im_hours' and lower(column_name) = 'hour_id';
        if v_count > 0 then return 1; end if;

	create sequence im_hours_seq;
	alter table im_hours add column hour_id integer
	default nextval('im_hours_seq');

        return 0;
end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



