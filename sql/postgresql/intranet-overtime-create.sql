-- /packages/intranet-overtime/sql/postgresql/intranet-overtime-create.sql
--
-- Copyright (c) 2011 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author klaus.hofeditz@project-open.com

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
	'Overtime Balance Component',		-- plugin_name
	'intranet-overtime',			-- package_name
	'left',					-- location
	'/intranet/users/view',			-- page_url
	null,					-- view_name
	200,					-- sort_order
	'im_overtime_balance_component -user_id_from_search $user_id',
	'lang::message::lookup "" intranet-overtime.OvertimeBalanceComponent "Overtime Balance Component"'
);


SELECT im_component_plugin__new (
        null,                                   -- plugin_id
        'im_component_plugin',                  -- object_type
        now(),                                  -- creation_date
        null,                                   -- creation_user
        null,                                   -- creation_ip
        null,                                   -- context_id
        'RWH Balance Component',	           	-- plugin_name
        'intranet-overtime',                    -- package_name
        'left',                                 -- location
		'/intranet/users/view',					-- page_url
        null,                                   -- view_name
        210,                                    -- sort_order
        'im_rwh_balance_component -user_id_from_search $user_id',
        'lang::message::lookup "" intranet-overtime.RwhBalanceComponent "RWH Balance Component"'
);


CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS INTEGER AS '
 
declare
        v_plugin_id             integer;
	v_employees		integer; 
begin

	select group_id into v_employees from groups where group_name = ''Employees'';

        select  plugin_id
        into    v_plugin_id
        from    im_component_plugins pl
        where   plugin_name = ''RWH Balance Component'';
 
        PERFORM im_grant_permission(v_plugin_id, v_employees, ''read'');
 
        select  plugin_id
        into    v_plugin_id
        from    im_component_plugins pl
        where   plugin_name = ''Overtime'';

        PERFORM im_grant_permission(v_plugin_id, v_employees, ''read'');

        return 1;
 
end;' LANGUAGE 'plpgsql';
 
SELECT inline_0 ();
DROP FUNCTION inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
        v_count                 integer;
begin
        select count(*) into v_count from user_tab_columns
        where lower(table_name) = ''im_employees'' and lower(column_name) = ''overtime_balance'';

        if v_count > 0 
	    then 
	    RAISE NOTICE ''Notice: intranet-overtime-create.sql - column overtime_balance already exists'';
	    else 
	       alter table im_employees add column overtime_balance numeric(12,2) DEFAULT 0;
	    end if;

        select count(*) into v_count from user_tab_columns
        where lower(table_name) = ''im_employees'' and lower(column_name) = ''rwh_days_per_year'';

        if v_count > 0
        then
                RAISE NOTICE ''Notice: intranet-overtime-create.sql - column rwh_balance already exists'';
        else
                alter table im_employees add column rwh_days_per_year numeric(12,2) DEFAULT 0;
        end if;

        select count(*) into v_count from user_tab_columns
        where lower(table_name) = ''im_employees'' and lower(column_name) = ''overtime_balance'';

        if v_count > 0
        then
                RAISE NOTICE ''Notice: intranet-overtime-create.sql - column overtime_balance exists'';
        else
                alter table im_employees add column overtime_balance numeric(12,2) DEFAULT 0;
        end if;

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
        v_count                 integer;
begin
        select count(*) into v_count from im_view_columns where column_id = 5634;
        if v_count > 0
        then
                RAISE NOTICE ''Error in intranet-overtime-create.sql: Column ID 5634 already exists'';
        else
		insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
		sort_order) values (5634,56,''Reduced Working Hours (year)'',''$rwh_days_per_year'', 36);
        end if;
        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create sequence im_overtime_bookings_seq start 1;

create table im_overtime_bookings (
        overtime_booking_id     integer
                                primary key,
        booking_date            date
                                not null,
        user_id                 integer
                                not null,
        comment		        	varchar(400), 
        days	                float
);


