-- indicators-helpdesk.sql


create or replace function inline_0 ()
returns integer as $body$
DECLARE
	v_id	integer;
BEGIN
	v_id := im_indicator__new(
		null,					-- ObjectID
		'im_indicator',				-- Object type (="im_indicator")
		now(),					-- Creation date
		0,					-- Creation user (0=guest)
		'',					-- Creation IP
		null,					-- ContextID  (always null)
		'Open Tickets',				-- Pretty Name
		'helpdesk_open_tickets_yesterday',	-- Label
		15110,					-- Indicator type
		15000,					-- Open status
		'
select	count(*)
from	im_tickets t,
	acs_objects o
where	t.ticket_id = o.object_id and
	o.creation_date >= now()::date-1 and
	o.creation_date <  now()::date
		',					-- Indicator SQL
		0,					-- Min value
		100,					-- Max value
		5					-- # bins
	);

	update im_indicators set
		indicator_section_id = 15255		-- Helpdesk
	where indicator_id = v_id;

	update im_reports set
		report_description = 'Counts the number of tickets currently open.'
	where report_id = v_id;

		return 0;
end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

