-- /packages/intranet-ganttproject/sql/postgresql/intranet-ganttproject-create.sql
--
-- Copyright (c) 2010 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

SELECT im_menu__new (
	null,						-- p_menu_id
	'im_menu',					-- object_type
	now(),						-- creation_date
	null,						-- creation_user
	null,						-- creation_ip
	null,						-- context_id
	'intranet-resource-management',			-- package_name
	'projects_resource_planning',			-- label
	'Resource Planning',				-- name
	'/intranet-resource-management/resources-planning', -- url
	0,						-- sort_order
	(select menu_id from im_menus where label = 'projects'),
	null						-- p_visible_tcl
);


-- Delete the old menu
SELECT im_menu__delete(
	(select	menu_id
	from	im_menus
	where	label = 'projects_gantt_resources'
	)
);



---------------------------------------------------------
-- Report Menu
---------------------------------------------------------


create or replace function inline_0 ()
returns integer as '
declare
	v_menu			integer;
	v_main_menu 		integer;
	v_reporting_menu 	integer;
        v_employees             integer;
        v_accounting            integer;
        v_senman                integer;
        v_customers             integer;
        v_freelancers           integer;
        v_proman                integer;
        v_admins                integer;
	v_reg_users		integer;
BEGIN
    select group_id into v_admins from groups where group_name = ''P/O Admins'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';
    select group_id into v_proman from groups where group_name = ''Project Managers'';
    select group_id into v_accounting from groups where group_name = ''Accounting'';
    select group_id into v_employees from groups where group_name = ''Employees'';
    select group_id into v_customers from groups where group_name = ''Customers'';
    select group_id into v_freelancers from groups where group_name = ''Freelancers'';
    select group_id into v_reg_users from groups where group_name = ''Registered Users'';

    select menu_id into v_reporting_menu from im_menus where label=''reporting'';

    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-reporting'', -- package_name
        ''reporting-pm'',	-- label
        ''Project Management'',		-- name
        ''/intranet-reporting/'', -- url
        230,                    -- sort_order
        v_reporting_menu,       -- parent_menu_id
        null                    -- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_senman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_proman, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_accounting, ''read'');
    PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');

    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


-- Menu in ProjectListPage
--
SELECT im_menu__new (
	null,						-- p_menu_id
	'im_menu',					-- object_type
	now(),						-- creation_date
	null,						-- creation_user
	null,						-- creation_ip
	null,						-- context_id
	'intranet-resource-management',			-- package_name
	'reporting-pm-resource-planning',		-- label
	'Resource Planning Report',			-- name
	'/intranet-resource-management/resources-planning', -- url
	0,						-- sort_order
	(select menu_id from im_menus where label = 'reporting-pm'),
	null						-- p_visible_tcl
);




---------------------------------------------------------
-- Components
---------------------------------------------------------

-- Component in member-add page
--
SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'Resource Availability Component',	-- plugin_name
	'intranet-ganttproject',		-- package_name
	'bottom',				-- location
	'/intranet/member-add',			-- page_url
	null,					-- view_name
	110,					-- sort_order
	'im_resource_mgmt_resource_planning_add_member_component',
	'lang::message::lookup "" intranet-ganttproject.Resource_Availability "Resource Availability"'
);


CREATE OR REPLACE FUNCTION im_absences_working_days_period(integer, character varying, character varying)
  RETURNS SETOF record AS
'

-- Returns dates of "work days" for a given period (record of type 'date') 
-- whereas: "work days" = Number of days in period - absences - bank holidays - weekends (Sat/Sun) 
-- Expects start_date and end_date in ANSI/ISO format YYYY-MM-DD

declare
        v_user_id               ALIAS FOR $1;
        v_start_date            ALIAS FOR $2;
        v_end_date              ALIAS FOR $3;
        v_count                 integer;
        v_seperator             CHAR DEFAULT ''-'';
        v_date_weekday          date;
        v_dow                   integer; 		 
        sql_result              record;
        r                       record;
begin
	FOR r in
	
	SELECT
        	result.all_days_in_period as working_day
	FROM
		(
		        (SELECT
                		*
			FROM
        	        	im_day_enumerator(to_date(v_start_date,''yyyy-mm-dd''), to_date(v_end_date,''yyyy-mm-dd''))
	       		AS
        	        	all_days_in_period
			) series

        LEFT JOIN

	        (SELECT
        	        d as absence_day
	        from
        	        im_user_absences a,
                	users u,
	                (select im_day_enumerator as d from im_day_enumerator(to_date(v_start_date,''yyyy-mm-dd''), to_date(v_end_date,''yyyy-mm-dd''))) d
	        where
        	        a.owner_id = u.user_id and
                	a.start_date <=  to_date(v_start_date,''yyyy-mm-dd'')::date and
	                a.end_date >= to_date(v_start_date,''yyyy-mm-dd'')::date and
        	        d.d between a.start_date and a.end_date and
                	u.user_id = v_user_id
	        UNION
        	        SELECT
                	        d as absence_day
	                FROM
        	                im_user_absences a,
                	        (select im_day_enumerator as d from im_day_enumerator(to_date(v_start_date,''yyyy-mm-dd''), to_date(v_end_date,''yyyy-mm-dd''))) d
	                WHERE
        	                a.start_date <=  to_date(v_end_date,''yyyy-mm-dd'')::date and
                	        a.end_date >= to_date(v_start_date,''yyyy-mm-dd'')::date and
                        	d.d between a.start_date and a.end_date and
	                        a.absence_type_id = 5005
                ) absence_days_month
        ON
                series.all_days_in_period = absence_days_month.absence_day
	) result

	WHERE
        	result.absence_day IS NULL
	LOOP
        	-- v_date_weekday = v_year || v_seperator || v_month || v_seperator || r.working_day;
	        -- select into v_dow extract (dow from v_date_weekday);
	        select into v_dow extract (dow from r.working_day);
        	IF v_dow <> 0 AND v_dow <> 6 THEN
                	return next r;
	        END IF;
	END LOOP;
end;'
  LANGUAGE 'plpgsql' VOLATILE;


CREATE OR REPLACE FUNCTION im_absences_working_days_period_weekend_only(character varying, character varying)
  RETURNS SETOF record AS
'

-- Returns the "work days" for a given period 
-- whereas: "work days" = Number of days in period - absences - bank holidays - weekends 
-- Expects start_date and end_date as YYYY/MM/DD

declare
        v_start_date            ALIAS FOR $1;
        v_end_date              ALIAS FOR $2;
        v_count                 integer;
        v_seperator             CHAR DEFAULT ''-'';
        v_date_weekday          date;
        v_dow                   integer; 		 
        sql_result              record;
        r                       record;
begin
	FOR r in
	
	SELECT
        	series.all_days_in_period as working_day
	FROM
		        (SELECT
                		*
			FROM
        	        	im_day_enumerator(to_date(v_start_date,''yyyy-mm-dd''), to_date(v_end_date,''yyyy-mm-dd''))
	       		AS
        	        	all_days_in_period
			) series
	LOOP
	        select into v_dow extract (dow from r.working_day);
        	IF v_dow <> 0 AND v_dow <> 6 THEN
                	return next r;
	        END IF;
	END LOOP;
end;'
  LANGUAGE 'plpgsql' VOLATILE;
