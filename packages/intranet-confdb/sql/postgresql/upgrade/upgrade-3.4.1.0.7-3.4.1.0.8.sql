-- upgrade-3.4.1.0.6-3.4.1.0.8.sql

SELECT acs_log__debug('/packages/intranet-confdb/sql/postgresql/upgrade/upgrade-3.4.1.0.7-3.4.1.0.8.sql','');


SELECT im_category_new(30540, 'Associate', 'Intranet Ticket Action');


update im_biz_object_urls 
set url = '/intranet-confdb/new?form_mode=display&ticket_id='
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
	'Conf Item Related Objects',	-- plugin_name
	'intranet-confdb',		-- package_name
	'right',			-- location
	'/intranet-confdb/new',		-- page_url
	null,				-- view_name
	91,				-- sort_order
	'im_conf_item_related_objects_component -conf_item_id $conf_item_id',
	'lang::message::lookup "" intranet-confdb.Conf_Item_Related_Objects "Conf Item Related Objects"'
);

SELECT acs_permission__grant_permission(
        (select plugin_id from im_component_plugins where plugin_name = 'Conf Item Related Objects' and package_name = 'intranet-confdb'),
        (select group_id from groups where group_name = 'Employees'),
        'read'
);


