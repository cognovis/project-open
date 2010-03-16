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


-- Create menu item and set permissions
-- 

create or replace function inline_1 ()
returns integer as '
declare
        v_menu                  integer;
        v_parent_menu    	integer;
        v_admins                integer;
	v_managers		integer;
	v_hr_managers		integer;
begin

    select group_id into v_admins from groups where group_name = ''P/O Admins'';
    select group_id into v_managers from groups where group_name = ''Senior Managers'';
    select group_id into v_hr_managers from groups where group_name = ''HR Managers'';

    select menu_id into v_parent_menu from im_menus where label=''timesheet2_absences'';

    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-timesheet2'', -- package_name
        ''capacity-planning'',  -- label
        ''Capacity Planning'',  -- name
        ''/intranet-timesheet2/capacity-planning'', -- url
        500,                    -- sort_order
        v_parent_menu,           -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_managers, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_hr_managers, ''read'');

    return 0;
end;' language 'plpgsql';
select inline_1 ();
drop function inline_1();
