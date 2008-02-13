
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


create or replace function im_day_enumerator (
	date, date
) returns setof date as '
declare
	p_start_date		alias for $1;
	p_end_date		alias for $2;
	v_date			date;
BEGIN
	v_date := p_start_date;
	WHILE (v_date < p_end_date) LOOP
		RETURN NEXT v_date;
		v_date := v_date + 1;
	END LOOP;
	RETURN;
end;' language 'plpgsql';


create or replace function im_day_enumerator_weekdays (
	date, date
) returns setof date as '
declare
	p_start_date		alias for $1;
	p_end_date		alias for $2;
	v_date			date;
	v_weekday		integer;
BEGIN
	v_date := p_start_date;
	WHILE (v_date < p_end_date) LOOP

		v_weekday := to_char(v_date, ''D'');
		IF v_weekday != 1 AND v_weekday != 7 THEN
			RETURN NEXT v_date;
		END IF;
		v_date := v_date + 1;
	END LOOP;
	RETURN;
end;' language 'plpgsql';




SELECT acs_privilege__create_privilege('edit_companies_all','Edit All Companies','Edit All Companies');
SELECT acs_privilege__add_child('admin', 'edit_companies_all');
