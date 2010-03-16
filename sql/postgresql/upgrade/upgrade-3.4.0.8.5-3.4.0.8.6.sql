-- upgrade-3.4.0.8.5-3.4.0.8.6.sql

SELECT acs_log__debug('/packages/intranet-timesheet2/sql/postgresql/upgrade/upgrade-3.4.0.8.5-3.4.0.8.6.sql','');

-- table structure - versioning not yet supported 

create sequence im_capacity_planning_id_seq;

create table im_capacity_planning (
        id                      integer
                                primary key
				default nextval('im_capacity_planning_id_seq'),
        user_id                 integer,
        project_id              integer,
        month			integer,
	year			integer,
        days_capacity           float,
	last_modified		timestamptz
);

alter table im_capacity_planning add constraint im_capacity_planning_un unique (id, user_id, project_id, month, year);

-- returns number of absence days for given absence type, month and user
--

create or replace function im_absences_month_absence_type (user_id integer, month integer, year integer, absence_type_id integer)
returns setof record as '

declare
        v_user_id               ALIAS FOR $1;
        v_month                 ALIAS FOR $2;
        v_year                  ALIAS FOR $3;
        v_absence_type_id       ALIAS FOR $4;
        v_default_date_format   varchar(10) := ''yyyy/mm/dd'';
        v_dow                   integer;
        v_month_found           integer;
        v_sql_result            record;
        v_record                record;
        v_searchsql             text;

begin
        FOR v_record IN
                select
                        a.start_date,
                        a.end_date
                from
                        im_user_absences a
                where
                        a.owner_id = v_user_id and
                        a.absence_type_id = v_absence_type_id
        LOOP
                v_searchsql = ''select im_day_enumerator as d from im_day_enumerator
                (to_date('''''' || v_record.start_date || '''''', '''''' || v_default_date_format ||  ''''''), to_date('''''' || v_record.end_date || '''''', '''''' || v_default_date_format || '''''')+1)'';
                FOR v_sql_result IN EXECUTE v_searchsql
                LOOP
                        select into v_month_found date_part(''month'', v_sql_result.d);
                        IF v_month_found = v_month THEN
                                select into v_dow extract (dow from v_sql_result.d);
                                IF v_dow <> 0 AND v_dow <> 6 THEN
                                        return next v_sql_result;
                                END IF;
                        END IF;
                END LOOP;
        END LOOP;
end;'
language 'plpgsql';


-- returns number of week days, counts all days from monday to friday
--

CREATE OR REPLACE FUNCTION im_calendar_bizdays (start_date date, end_date date) 
RETURNS int AS '

declare
        v_start_date               ALIAS FOR $1;
        v_end_date                 ALIAS FOR $2;
	  number_biz_days		     integer;
begin

SELECT 
	count(*) 
INTO 
	 number_biz_days
FROM 
	(SELECT 
		extract(''weekday'' FROM v_start_date+x) AS weekday 
	 FROM 
		generate_series(0,v_end_date-v_start_date) x) AS foo 
	 WHERE 
		weekday BETWEEN 1 AND 5;

	return number_biz_days;
end;'
language 'plpgsql';
