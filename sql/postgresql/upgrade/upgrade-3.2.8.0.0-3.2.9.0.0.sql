-- upgrade-3.2.8.0.0-3.2.9.0.0.sql

create or replace function inline_1 ()
returns integer as '
declare
        v_count                 integer;
	v_menu_id		integer;
begin
	select	menu_id into v_menu_id
	from	im_menus
	where	label = ''reporting-timesheet-cube''
		and package_id = ''intranet-reporting'';

	PERFORM im_menu__delete(v_menu_id);

    return 0;
end;' language 'plpgsql';
select inline_1 ();
drop function inline_1();


create or replace function inline_1 ()
returns integer as '
declare
        v_count                 integer;
	v_menu_id		integer;
	row			RECORD;
begin
	FOR row IN
		select	*
		from	im_menus
		where	label like ''reporting-finance-%''
			and package_name = ''intranet-reporting''
	LOOP
		PERFORM im_menu__delete(row.menu_id);
	END LOOP;

	return 0;
end;' language 'plpgsql';
select inline_1 ();
drop function inline_1();


create or replace function inline_1 ()
returns integer as '
declare
        v_count                 integer;
	v_menu_id		integer;
	row			RECORD;
begin
	FOR row IN
		select	*
		from	im_menus
		where	(label like ''reporting-project-trans-%'' OR
			 label like ''reporting-trans-%'')
			and package_name = ''intranet-reporting''
	LOOP
		PERFORM im_menu__delete(row.menu_id);
	END LOOP;

	return 0;
end;' language 'plpgsql';
select inline_1 ();
drop function inline_1();


create or replace function inline_1 ()
returns integer as '
declare
        v_count                 integer;
        v_menu_id               integer;
        row                     RECORD;
begin
        FOR row IN
                select  *
                from    im_menus
                where   label like ''%cube%''
                        and package_name = ''intranet-reporting''
        LOOP
                PERFORM im_menu__delete(row.menu_id);
        END LOOP;

        return 0;
end;' language 'plpgsql';
select inline_1 ();
drop function inline_1();
