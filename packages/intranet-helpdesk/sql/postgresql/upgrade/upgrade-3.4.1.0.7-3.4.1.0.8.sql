-- upgrade-3.4.1.0.8-3.4.1.0.8.sql

SELECT acs_log__debug('/packages/intranet-helpdesk/sql/postgresql/upgrade/upgrade-3.4.1.0.7-3.4.1.0.8.sql','');


SELECT im_category_new(30540, 'Associate', 'Intranet Ticket Action');


update im_biz_object_urls 
set url = '/intranet-helpdesk/new?form_mode=display&ticket_id='
where object_type = 'im_ticket' and url_type = 'view';




-- ------------------------------------------------------
-- Show related objects
--
SELECT	im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Ticket Related Objects',	-- plugin_name
	'intranet-helpdesk',		-- package_name
	'right',			-- location
	'/intranet-helpdesk/new',	-- page_url
	null,				-- view_name
	91,				-- sort_order
	'im_biz_object_related_objects_component -object_id $ticket_id',
	'lang::message::lookup "" intranet-helpdesk.Ticket_Related_Objects "Ticket Related Objects"'
);

SELECT acs_permission__grant_permission(
        (select plugin_id from im_component_plugins where plugin_name = 'Ticket Related Objects' and package_name = 'intranet-helpdesk'),
        (select group_id from groups where group_name = 'Employees'),
        'read'
);



-- Delete the old "Related Tickets" component
create or replace function inline_0 ()
returns integer as $$
declare
	v_component_id		integer;
begin
	select	plugin_id into v_component_id
	from	im_component_plugins
	where	package_name = 'intranet-helpdesk' and
		plugin_name = 'Related Tickets';

	IF v_component_id IS NULL THEN return 1; END IF;

	PERFORM im_component_plugin__delete(v_component_id);

	return 0;
end;$$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

