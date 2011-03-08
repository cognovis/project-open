-- upgrade-3.4.1.0.3-3.5.0.0.0.sql

SELECT acs_log__debug('/packages/intranet-simple-survey/sql/postgresql/upgrade/upgrade-3.4.1.0.3-3.5.0.0.0.sql','');


create or replace function inline_0 ()
returns integer as '
declare
	v_plugin		integer;
begin
	v_plugin := im_component_plugin__new (
		null,					-- plugin_id
		''im_component_plugin'',		-- object_type
		now(),					-- creation_date
		null,					-- creation_user
		null,					-- creation_ip
		null,					-- context_id
		''Ticket Survey Component'',		-- plugin_name
		''intranet-simple-survey'',		-- package_name
		''right'',				-- location
		''/intranet-helpdesk/new'',		-- page_url
		null,					-- view_name
		120,					-- sort_order
		''im_survsimp_component $ticket_id''	-- component_tcl
	);
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
