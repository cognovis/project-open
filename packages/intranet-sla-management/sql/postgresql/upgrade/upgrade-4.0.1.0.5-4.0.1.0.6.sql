-- upgrade-4.0.1.0.5-4.0.1.0.6.sql

SELECT acs_log__debug('/packages/intranet-sla-management/sql/postgresql/upgrade/upgrade-4.0.1.0.5-4.0.1.0.6.sql','');



-- Add a field to im_tickets to store a calculated "resolution time"
create or replace function inline_0 ()
returns integer as $body$
DECLARE
	v_count		integer;
	v_attribute_id	integer;
BEGIN
	select count(*) into v_count from user_tab_columns
	where  lower(table_name) = 'im_tickets' and lower(column_name) = 'ticket_resolution_time';
	IF v_count = 0 THEN
		alter table im_tickets
		add ticket_resolution_time numeric(12,2);
	END IF;


	select count(*) into v_count from user_tab_columns
	where  lower(table_name) = 'im_tickets' and lower(column_name) = 'ticket_resolution_time_dirty';
	IF v_count = 0 THEN
		alter table im_tickets
		add ticket_resolution_time_dirty timestamptz;
	END IF;


	SELECT im_dynfield_attribute_new (
		'im_ticket', 'ticket_resolution_time', 'Resolution Time', 'numeric', 'integer', 'f', 9000, 'f', 'im_tickets'
	) INTO 	v_attribute_id;

	-- set permissions for ticket_resolution_time to "read only" for all types of tickets.
	update im_dynfield_type_attribute_map
	set display_mode = 'display'
	where attribute_id = v_attribute_id;

	return 0;
end; $body$ language 'plpgsql';
select inline_0();
drop function inline_0();

