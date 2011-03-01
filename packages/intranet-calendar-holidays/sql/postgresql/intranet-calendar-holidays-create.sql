-- /packages/intranet-calendar-holidays/sql/postgres/intranet-calendar-holidays-create.sql
--
-- Copyright (c) 2007 ]project-open[
-- All rights reserved.
--
-- @author      frank.bergmann@project-open.com

-- Holiday Calendar:
-- Setup the default that Saturday and Sundays are non-working days

drop table im_calendar_holidays;
create table im_calendar_holidays (
	day			date
				constraint im_calendar_holidays_nn
				not null 
				constraint im_calendar_holidays_pk
				primary key,
	year			char(4),
	year2			char(2),
	month_of_year		integer,
	day_of_month		integer,
	day_of_week		integer,
	week_of_year		integer,
	workday_p		char(1)
				constraint im_calendar_holidays_workday_ck
				check(workday_p in ('t', 'f')),
	holiday_type_id		integer
				constraint im_calendar_holidays_holiday_fk
				references im_categories,
	note			text
);



create or replace function inline_0 ()
returns integer as '
DECLARE
	row			record;
BEGIN
	FOR row IN
		select	
			day,
			to_char(day, ''YYYY'') as year,
			to_char(day, ''YY'') as year2,
			to_char(day, ''MM'')::integer as month_of_year,
			to_char(day, ''D'')::integer as day_of_week,
			to_char(day, ''DD'')::integer as day_of_month,
			to_char(day, ''DDD'')::integer as day_of_year,
			to_char(day, ''W'')::integer as week_of_month,
			to_char(day, ''IW'')::integer as week_of_year,
			to_char(day, ''Q'')::integer as quarter_of_year,
			CASE WHEN to_char(day, ''D'') between 2 and 6 THEN ''t'' ELSE ''f'' END as workday_p
		from
			( select im_day_enumerator as day
			  from	im_day_enumerator(
					to_date(''2000-01-01'', ''YYYY-MM-DD''), 
					to_date(''2019-12-31'', ''YYYY-MM-DD'')
				)
			) d
	LOOP

		insert into im_calendar_holidays (
			day, year, 
			month_of_year,
			day_of_month,
			day_of_week,
			week_of_year,
			workday_p
		) values (
			row.day, row.year, 
			row.month_of_year,
			row.day_of_month,
			row.day_of_week,
			row.week_of_year,
			row.workday_p
		);

	END LOOP;
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




create or replace function im_calendar_nth_workday (date, integer)
returns date as '
declare
	p_base_date		alias for $1;
	p_workdays		alias for $2;
	v_count			integer;

	v_workday_p		char(1);
	v_workdays		integer;
	v_caldays		integer;
begin
	v_count := 0;
	v_caldays := 0;
	v_workdays := p_workdays;

	WHILE v_workdays > 0 AND v_count < 100000 LOOP

		select	workday_p into v_workday_p
		from	im_calendar_holidays
		where	day = p_base_date + v_caldays + 1;

		IF v_workday_p THEN
			-- A workday: inc + dec
			v_workdays := v_workdays - 1;
			v_caldays := v_caldays + 1;
		ELSE
			-- A holiday: only increment calendar days
			v_caldays := v_caldays + 1;
		END IF;
		
		v_count := v_count + 1;

	END LOOP;

        return p_base_date + v_caldays;
end;' language 'plpgsql';

select im_calendar_nth_workday(now()::date, 0);
select im_calendar_nth_workday(now()::date, 1);
select im_calendar_nth_workday(now()::date, 2);
select im_calendar_nth_workday(now()::date, 3);
select im_calendar_nth_workday(now()::date, 4);



