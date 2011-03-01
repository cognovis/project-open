--upgrade-3.4.0.7.8-3.4.0.7.9.sql

SELECT acs_log__debug('/packages/intranet-calendar/sql/postgresql/upgrade/upgrade-3.4.0.7.8-3.4.0.7.9.sql','');


-- SourceForge #1798720
--
-- Eliminate a constraint on the calendar name
-- and replace by constraint on owner + calendar name




create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from pg_indexes
	where indexname = ''calendars_un_idx'';
	IF v_count > 0 THEN
		drop index calendars_un_idx;
	END IF;

	select count(*) into v_count from pg_constraint
	where lower(conname) = ''calendars_name_user_un'';
	IF v_count = 0 THEN 
		alter table calendars add constraint calendars_name_user_un UNIQUE (owner_id, calendar_name);
	END IF;

	RETURN 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

