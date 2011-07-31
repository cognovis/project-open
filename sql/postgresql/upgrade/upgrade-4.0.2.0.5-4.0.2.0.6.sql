-- upgrade-4.0.2.0.5-4.0.2.0.6.sql

SELECT acs_log__debug('/packages/intranet-sencha-ticket-tracker/sql/postgresql/upgrade/upgrade-4.0.2.0.5-4.0.2.0.6.sql','');


create or replace function inline_0 ()
returns integer as $body$
declare
	v_count integer;
begin
	select	count(*) into v_count from user_tab_columns
	where	lower(table_name) = 'im_tickets' and
		lower(column_name) = 'ticket_action_count';
	IF 0 != v_count THEN return 1; END IF;

	alter table im_tickets
	add ticket_action_count numeric(12,2) default 1.0;

	return 0;
end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

