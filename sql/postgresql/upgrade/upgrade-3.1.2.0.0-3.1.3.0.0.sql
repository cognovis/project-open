
-------------------------------------------------------------
-- Function used to enumerate days between stat_date and end_date
-------------------------------------------------------------




create function inline_0 () returns integer as '
-- Create a bitfromint4(integer) function if it doesn''t exists.
-- Due to a bug in PG 7.3 this function is absent in PG 7.3.
declare
	v_bitfromint4_count integer;
begin
	select into v_bitfromint4_count count(*) from pg_proc where proname = ''bitfromint4'';
	if v_bitfromint4_count = 0 then
		create or replace function bitfromint4 (integer) returns bit varying as ''
		begin
			return $1::bit(32);
		end;'' language ''plpgsql'' immutable strict;
	end if;
	return 1;
end;' language 'plpgsql';
select inline_0();
drop function inline_0();



-- There were trouble upgrading a Windows 3.1.2/7.4.4 version to V3.2 on PG 8.0.8
--
-- create or replace function bitfromint4 (integer) returns bit varying as '
-- begin
-- 	return $1::bit(32);
-- end;' language 'plpgsql' immutable strict;




create or replace function im_day_enumerator (
        date, date
) returns setof date as '
declare
        p_start_date            alias for $1;
        p_end_date              alias for $2;
        v_date                  date;
        v_counter               integer;
BEGIN
        v_date := p_start_date;
        v_counter := 100;
        WHILE (v_date < p_end_date AND v_counter > 0) LOOP
                RETURN NEXT v_date;
                v_date := v_date + 1;
                v_counter := v_counter - 1;
        END LOOP;
        RETURN;
end;' language 'plpgsql';

-- Test query
-- select * from im_day_enumerator(now()::date, now()::date + 7);



-- Add "edit_companies_all" privilege

create or replace function inline_0 ()
returns integer as '
declare
        v_count                 integer;
begin
        select count(*) into v_count from acs_privileges
        where privilege = ''edit_companies_all'';
        IF 0 != v_count THEN return 0; END IF;

	PERFORM acs_privilege__create_privilege(
		''edit_companies_all'',
		''Edit All Companies'',
		''Edit All Companies''
	);
	PERFORM acs_privilege__add_child(''admin'', ''edit_companies_all'');

    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

