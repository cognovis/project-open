-- upgrade-3.4.0.7.6-3.4.0.7.7.sql

SELECT acs_log__debug('/packages/intranet-security-update-client/sql/postgresql/upgrade/upgrade-3.4.0.7.6-3.4.0.7.7.sql','');



create or replace function inline_0 ()
returns integer as ' 
declare
    v_plugin            integer;
begin
    -- Allow importing Exchange Rates from ASUS server
    --
    v_plugin := im_component_plugin__new (
	null,					-- plugin_id
	''acs_object'',				-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	''Exchange Rates ASUS'',		-- plugin_name
	''intranet-security-update-client'',	-- package_name
        ''right'',				-- location
	''/intranet-exchange-rate/index'',	-- page_url
        null,					-- view_name
        10,					-- sort_order
        ''im_exchange_rate_update_component''	-- component_tcl
    );
    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


SELECT im_grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Exchange Rates ASUS'),
	(select group_id from groups where group_name = 'Accounting'), 
	'read'
);

SELECT im_grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Exchange Rates ASUS'),
	(select group_id from groups where group_name = 'Senior Managers'), 
	'read'
);
