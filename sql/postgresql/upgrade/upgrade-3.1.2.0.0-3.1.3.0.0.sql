
-------------------------------------------------------------
-- Function used to enumerate days between stat_date and end_date
-------------------------------------------------------------


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
select acs_privilege__create_privilege('edit_companies_all','Edit All Companies','Edit All Companies');
select acs_privilege__add_child('admin', 'edit_companies_all');

