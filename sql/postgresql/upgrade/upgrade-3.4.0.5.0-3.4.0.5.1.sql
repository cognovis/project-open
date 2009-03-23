-- upgrade-3.4.0.5.0-3.4.0.5.1.sql

SELECT acs_log__debug('/packages/intranet-reporting-finance/sql/postgresql/upgrade/upgrade-3.4.0.5.0-3.4.0.5.1.sql','');

-- Fix reinisch wrong report name
update im_menus set
	package_name = 'intranet-reporting-finance',
	url = '/intranet-reporting-finance/finance-expenses'
where
	url = '/intranet-reporting/finance-expenses'
;



create or replace function inline_1 ()
returns integer as '
declare
	v_menu			integer;
	v_admin_menu		integer;
	v_admins		integer;
	v_senman		integer;
	v_accounting		integer;
	v_count			integer;
begin
	select group_id into v_admins from groups where group_name = ''P/O Admins'';
	select group_id into v_accounting from groups where group_name = ''Accounting'';
	select group_id into v_senman from groups where group_name = ''Senior Managers'';

	select count(*) into v_count
	from im_menus where label = ''reporting-finance-cube'';
	IF v_count > 0 THEN return 0; END IF;

	select menu_id into v_admin_menu from im_menus where label=''reporting-finance'';

	v_menu := im_menu__new (
		null,				-- p_menu_id
		''acs_object'',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		''intranet-reporting-finance'',	-- package_name
		''reporting-finance-cube'',	-- label
		''Finance Cube'',		-- name
		''/intranet-reporting-finance/finance-cube?'', -- url
		110,				-- sort_order
		v_admin_menu,			-- parent_menu_id
		null				-- p_visible_tcl
	);

	PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
	return 0;
end;' language 'plpgsql';
select inline_1 ();
drop function inline_1();




update im_menus set
	url = '/intranet-reporting-finance/finance-cube?'
where	url = '/intranet-reporting/finance-cube?';



