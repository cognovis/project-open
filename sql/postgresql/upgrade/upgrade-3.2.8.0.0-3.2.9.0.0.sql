-- upgrade-3.2.8.0.0-3.2.9.0.0.sql

create or replace function inline_1 ()
returns integer as '
declare
        v_count                 integer;
	v_menu_id		integer;
begin
	select	menu_id into v_menu_id
	from	im_menus
	where	label = ''reporting-timesheet-cube'';


	PERFORM im_menu__delete(v_menu_id);

    return 0;
end;' language 'plpgsql';
select inline_1 ();
drop function inline_1();
