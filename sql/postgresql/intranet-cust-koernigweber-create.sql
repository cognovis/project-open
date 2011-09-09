-- /packages/intranet-cust-kw/sql/postgres/intranet-cust-kw-create.sql
--
-- Copyright (C) 1999-2011 various parties
--
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author	klaus.hofeditz@project-open.com

-------------------------------------------------------------


SELECT im_lang_add_message('en_US','intranet-cust-koernigweber','Mail_Reminder_Log_Hours_Text','Please log your hours\nBest regards\n%current_user_name%');
SELECT im_lang_add_message('de_DE','intranet-cust-koernigweber','Mail_Reminder_Log_Hours_Text','Bitte erfassen Sie Ihre Stunden und erteilen Sie die Freigabe\n\nMit freundlichen Gruessen\n%current_user_name%');

SELECT im_lang_add_message('en_US','intranet-cust-koernigweber','Mail_Reminder_Log_Hours_Subject','Reminder: Time sheet ');
SELECT im_lang_add_message('de_DE','intranet-cust-koernigweber','Mail_Reminder_Log_Hours_Subject','Erinnerung: Stundenerfassung');

SELECT im_lang_add_message('en_US','intranet-cust-koernigweber','TS_WF_Not_Yet_Confirmed','To be confirmed');
SELECT im_lang_add_message('de_DE','intranet-cust-koernigweber','TS_WF_Not_Yet_Confirmed','Zu best&auml;tigen');

SELECT im_lang_add_message('en_US','intranet-cust-koernigweber','TS_WF_Approved','Confirmed');
SELECT im_lang_add_message('de_DE','intranet-cust-koernigweber','TS_WF_Approved','Best&auml;tigt');

SELECT im_lang_add_message('en_US','intranet-cust-koernigweber','TS_WF_Remind','Remind');
SELECT im_lang_add_message('de_DE','intranet-cust-koernigweber','TS_WF_Remind','Erinnern');

SELECT im_lang_add_message('en_US','intranet-cust-koernigweber','Emp_Cust_Internal_costs','Internal Costs');
SELECT im_lang_add_message('de_DE','intranet-cust-koernigweber','Emp_Cust_Internal_costs','Interne Kosten');

SELECT im_lang_add_message('en_US','intranet-cust-koernigweber','Emp_Cust_Costs_Based_On_Price_Matrix','Invoicable<br>according to<br>Price Matrix');
SELECT im_lang_add_message('de_DE','intranet-cust-koernigweber','Emp_Cust_Costs_Based_On_Price_Matrix','Abrechenbar<br>lt. E/C Preis-Matrix');

SELECT im_lang_add_message('en_US','intranet-cust-koernigweber','Day','Day');
SELECT im_lang_add_message('de_DE','intranet-cust-koernigweber','Day','Tag');

SELECT im_lang_add_message('en_US','intranet-cust-koernigweber','Hour','Hour');
SELECT im_lang_add_message('de_DE','intranet-cust-koernigweber','Hour','Stunden');

SELECT im_lang_add_message('en_US','intranet-cust-koernigweber','AbsenceTimeframe','Timeframe');
SELECT im_lang_add_message('de_DE','intranet-cust-koernigweber','AbsenceTimeframe','Zeitraum');


-- -----------------------------------------------------------------
-- CUSTOMER PROJECT TYPES
-- -----------------------------------------------------------------

-- create table to manage information which project types are allowed 

create table im_customer_project_type (
        company_id              integer
                                references im_companies,
        project_type_id         integer not null,
        unique(company_id, project_type_id)
);


SELECT im_component_plugin__new (
        null,                           -- plugin_id
        'im_component_plugin',          -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Allowed Project Types',        -- plugin_name
        'intranet-cust-koernigweber',   -- package_name
        'right',                        -- location
        '/intranet/companies/view',     -- page_url
        null,                           -- view_name
        15,                             -- sort_order
        'im_allowed_project_types $company_id ' -- component_tcl
);


-- set permissions for above Plugin

create or replace function inline_1 ()
returns integer as '
declare
        v_plugin_id                  integer;
        v_project_managers           integer;
begin
        select group_id into v_project_managers from groups where group_name = ''Project Managers'';

        select  plugin_id
        into    v_plugin_id
        from    im_component_plugins pl
        where   plugin_name = ''Allowed Project Types'';

        PERFORM acs_permission__grant_permission(v_plugin_id, v_project_managers, ''read'');
        return 0;
end;'
language 'plpgsql';
select inline_1 ();
drop function inline_1();

-- -----------------------------------------------------------------
-- Customer Approval WF 
-- -----------------------------------------------------------------

select acs_object_type__create_type (
        'project_approval2_wf',           -- object_type
        'Project Close Approval',         -- pretty_name
        'Project Close Approval',         -- pretty_plural
        'workflow',        		  -- supertype
        'project_approval2_wf_cases',     -- table_name
        'case_id',           		  -- id_column
        'project_approval2_wf',           -- package_name
        'f',                    	  -- abstract_p
        null,                   	  -- type_extension_table
        'null'      			  -- name_method
);

insert into acs_object_type_tables (object_type,table_name,id_column) values ('project_approval2_wf', 'project_approval2_wf_cases', 'case_id');

CREATE OR REPLACE FUNCTION im_workflow__assign_to_project_manager(integer, text)
  RETURNS integer AS
'
declare
        p_task_id               alias for $1;
        p_custom_arg            alias for $2;

        v_transition_key        varchar;
        v_object_type           varchar;
        v_case_id               integer;
        v_object_id             integer;
        v_creation_user         integer;
        v_creation_ip           varchar;
        v_project_manager_id    integer;
        v_project_manager_name  varchar;

        v_journal_id            integer;
        v_workflow_key          varchar;

 begin
        -- Get information about the transition and the ''environment''
        select  tr.transition_key, t.case_id, c.object_id, o.creation_user, o.creation_ip, o.object_type
        into    v_transition_key, v_case_id, v_object_id, v_creation_user, v_creation_ip, v_object_type
        from    wf_tasks t, wf_cases c, wf_transitions tr, acs_objects o
        where   t.task_id = p_task_id
                and t.case_id = c.case_id
                and o.object_id = t.case_id
                and t.workflow_key = tr.workflow_key
                and t.transition_key = tr.transition_key;

        select attr_value into v_workflow_key from apm_parameter_values where parameter_id in
                (select parameter_id from apm_parameters where package_key like ''intranet-timesheet2-workflow'' and  parameter_name = ''DefaultWorkflowKey'');

        RAISE NOTICE ''im_workflow__assign_to_project_manager: Found workflow: %: '', v_workflow_key;

        IF v_workflow_key = '''' THEN
                v_workflow_key := ''timesheet_approval_wf'';
                RAISE NOTICE ''im_workflow__assign_to_project_manager: No parameter found, set workflow_key to: %: '', v_workflow_key;
        END IF;

        IF v_object_type = v_workflow_key THEN
                select  project_lead_id into v_project_manager_id from im_projects
                where   project_id in (select conf_project_id from im_timesheet_conf_objects where conf_id = v_object_id);
                RAISE NOTICE ''im_workflow__assign_to_project_manager: Project Manager ID: %: '', v_project_manager_id;
        ELSE
                select  project_lead_id into v_project_manager_id from im_projects
                where   project_id = v_object_id;
        END IF;
        select im_name_from_id(v_project_manager_id) into v_project_manager_name;

        IF v_project_manager_id is not null THEN
                v_journal_id := journal_entry__new(
                    null, v_case_id,
                    v_transition_key || '' assign_to_project_manager '' || v_project_manager_name,
                    v_transition_key || '' assign_to_project_manager '' || v_project_manager_name,
                    now(), v_creation_user, v_creation_ip,
                    ''Assigning to user'' || v_project_manager_name
                );
                PERFORM workflow_case__add_task_assignment(p_task_id, v_project_manager_id, ''f'');
                PERFORM workflow_case__notify_assignee (p_task_id, v_project_manager_id, null, null,
                        ''wf_'' || v_object_type || ''_assignment_notif'');
        END IF;
        return 0;
end;'
  LANGUAGE 'plpgsql' VOLATILE;


-- -----------------------------------------------------------------
-- CUSTOMER PRICES
-- -----------------------------------------------------------------

-- create table to manage Employee/Customer Price Matrix 

create table im_customer_prices (
        id                      integer
                                primary key,
        user_id                 integer
                                constraint im_customer_prices_user_fk
                                references users,
        object_id               integer not null,
        amount                  numeric(12,2),
        currency                char(3)
                                constraint im_costs_currency_fk
                                references currency_codes(iso),
        project_type_id         integer,
        unique(user_id, object_id, project_type_id)
);

create index im_customer_prices_idx on im_customer_prices(id);


select acs_object_type__create_type (
        'im_employee_customer_price',           -- object_type
        'Employee Customer Price',              -- pretty_name
        'Employee Customer Price',             	-- pretty_plural
        'im_biz_object',        		-- supertype
        'im_customer_prices',      		-- table_name
        'id',           			-- id_column
        'im_customer_prices',      		-- package_name
        'f',                  			-- abstract_p
        null,                  			-- type_extension_table
        'im_emp_cust_price__name'      		-- name_method
);

insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_employee_customer_price', 'im_customer_prices', 'id');

create or replace function im_employee_customer_price__update(int4,varchar,timestamptz,int4,varchar,int4,int,int,numeric,varchar, int) returns int4 as '
        DECLARE
                p_id              alias for $1;
                p_object_type     alias for $2;
                p_creation_date   alias for $3;
                p_creation_user   alias for $4;
                p_creation_ip     alias for $5;
                p_context_id      alias for $6;

                p_user_id         alias for $7;
                p_object_id       alias for $8;
                p_amount          alias for $9;
                p_currency        alias for $10;
		p_project_type_id alias for $11;

                v_id              integer;
                v_count           integer;
        BEGIN
                RAISE NOTICE ''KHD: user_id: %; object_id: %; project_type_id:%; '', p_user_id, p_object_id, p_project_type_id;  
                select count(*) into v_count from im_customer_prices where user_id = p_user_id and object_id = p_object_id and project_type_id = p_project_type_id;
                RAISE NOTICE ''KHD: Count: %'', v_count;  

                IF v_count > 0 THEN
                        update im_customer_prices set amount = p_amount where object_id = p_object_id and user_id = p_user_id;
                ELSE
                        v_id := acs_object__new (
                                p_id,
                                p_object_type,
                                p_creation_date,
                                p_creation_user,
                                p_creation_ip,
                                p_context_id
                        );

                        insert into im_customer_prices (
                                id, user_id, object_id, amount, currency, project_type_id
                        ) values (
                                v_id, p_user_id, p_object_id, p_amount, p_currency, p_project_type_id
                        );
                END IF;
                return v_id;
end;' language 'plpgsql';


-- Create a plugin for the Company View Page.
SELECT im_component_plugin__new (
        null,                           -- plugin_id
        'im_component_plugin',          -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Price List (Company)',			 -- plugin_name
        'intranet-cust-koernigweber',   -- package_name
        'right',                        -- location
        '/intranet/companies/view',     -- page_url
        null,                           -- view_name
        15,                             -- sort_order
        'im_customer_price_list $company_id $user_id 0 $return_url "" "" $also_add_to_group' -- component_tcl
);

update im_component_plugins
set title_tcl = 'lang::message::lookup "" intranet-cust-koernigweber.TitlePortletEmployeeCustomerPriceList "Price List"'
where plugin_name = 'Price List (Company)';


-- Create a plugin for the Project View Page.
SELECT im_component_plugin__new (
        null,                           -- plugin_id
        'im_component_plugin',          -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Price List (Project)',		-- plugin_name
        'intranet-cust-koernigweber',   -- package_name
        'right',                        -- location
        '/intranet/projects/view',      -- page_url
        null,                           -- view_name
        15,                             -- sort_order
        'im_customer_price_list $project_id $user_id 0 $return_url "" "" ""' -- component_tcl
);

update im_component_plugins
set title_tcl = 'lang::message::lookup "" intranet-cust-koernigweber.TitlePortletProjectPriceList "Price List"'
where plugin_name = 'Price List (Project)';


-- set permissions for above Plugins

create or replace function inline_1 ()
returns integer as '
declare
        v_plugin_id                  integer;
	v_project_managers	     integer;
begin
        select group_id into v_project_managers from groups where group_name = ''Project Managers'';

        select  plugin_id
        into    v_plugin_id
        from    im_component_plugins pl
        where   plugin_name = ''Price List (Project)'';

        PERFORM acs_permission__grant_permission(v_plugin_id, v_project_managers, ''read'');

        select  plugin_id
        into    v_plugin_id
        from    im_component_plugins pl
        where   plugin_name = ''Price List (Company)'';

        PERFORM acs_permission__grant_permission(v_plugin_id, v_project_managers, ''read'');

        return 0;
end;' 
language 'plpgsql';
select inline_1 ();
drop function inline_1();




-- -----------------------------------------------------------------
-- TIMESHEET CONFIRMATION WF 
-- -----------------------------------------------------------------

-- create menu item for managing timesheet confirmation workflow

create or replace function inline_1 ()
returns integer as '
declare
        v_menu                  integer;
        v_parent_menu     	integer;
        v_project_managers      integer;
begin
        select group_id into v_project_managers from groups where group_name = ''Project Managers'';

        -- select menu_id into v_parent_menu from im_menus where label = ''timesheet2_timesheet'';
        select menu_id into v_parent_menu from im_menus where label = ''timesheet_hours_new_admin'';

        v_menu := im_menu__new (
                null,                                   -- p_menu_id
                ''im_menu'',                            -- object_type
                now(),                                  -- creation_date
                null,                                   -- creation_user
                null,                                   -- creation_ip
                null,                                   -- context_id
                ''intranet-cust-koernigweber'',   	-- package_name
                ''timesheet_workflow_reminder_confirmation'', -- label
                ''Erinnern/Genehmigen von Stunden'',   -- name
                ''/intranet-cust-koernigweber/monthly-report-wf-extended'',   -- url
                40,                                    	-- sort_order
                v_parent_menu,                          -- parent_menu_id
                null                                    -- p_visible_tcl
        );

        PERFORM acs_permission__grant_permission(v_menu, v_project_managers, ''read'');
        return 0;
end;' language 'plpgsql';

# ### evaluating - will probably need to be added with business logic 
# select inline_1 ();
# ### 

drop function inline_1();




create or replace function inline_1 ()
returns integer as '
declare
        v_menu                  integer;
        v_parent_menu           integer;
        v_project_managers      integer;
        v_employees 		integer;
begin
        select group_id into v_project_managers from groups where group_name = ''Project Managers'';
        select group_id into v_employees from groups where group_name = ''Employees'';

        select menu_id into v_parent_menu from im_menus where label = ''timesheet2_timesheet'';

        v_menu := im_menu__new (
                null,                                   -- p_menu_id
                ''im_menu'',                            -- object_type
                now(),                                  -- creation_date
                null,                                   -- creation_user
                null,                                   -- creation_ip
                null,                                   -- context_id
                ''intranet-timesheet2-workflow'',       -- package_name
                ''timesheet_workflow_confirm'', -- label
                ''Freigabe geloggter Stunden f&uuml;r diesen Monat'',		-- name
                ''/intranet-timesheet2-workflow/conf-objects/new-timesheet-workflow?'',   -- url
                40,                                     -- sort_order
                v_parent_menu,                          -- parent_menu_id
                null                                    -- p_visible_tcl
        );

        PERFORM acs_permission__grant_permission(v_menu, v_project_managers, ''read'');
        PERFORM acs_permission__grant_permission(v_menu, v_employees, ''read'');

        return 0;
end;' language 'plpgsql';
select inline_1 ();
drop function inline_1();




create or replace function inline_1 ()
returns integer as '
declare
        v_menu                  integer;
        v_parent_menu           integer;
        v_senior_managers       integer;
        v_project_managers      integer;
begin
        select group_id into v_project_managers from groups where group_name = ''Project Managers'';
        select group_id into v_senior_managers from groups where group_name = ''Senior Managers'';

        select menu_id into v_parent_menu from im_menus where label = ''reporting-finance'';

        v_menu := im_menu__new (
                null,                                   	-- p_menu_id
                ''im_menu'',                            	-- object_type
                now(),                                  	-- creation_date
                null,                                   	-- creation_user
                null,                                   	-- creation_ip
                null,                                   	-- context_id
                ''intranet-cust-koernigweber'',   		-- package_name
                ''project_profit_ratio_employee_customer_price_matrix'',		-- label
                ''Project Profit Ratio Employee/Customer Price Matrix'',      		-- name
                ''/intranet-cust-koernigweber/timesheet-finance-emp-cust-matrix'',   	-- url
                500,                                   		-- sort_order
                v_parent_menu,                          	-- parent_menu_id
                null                                    	-- p_visible_tcl
        );

        PERFORM acs_permission__grant_permission(v_menu, v_project_managers, ''read'');
        PERFORM acs_permission__grant_permission(v_menu, v_senior_managers, ''read'');

        return 0;
end;' language 'plpgsql';
select inline_1 ();
drop function inline_1();



-- Accountants shouldn't be allowed to re-assign tasks 
-- privilige is set in /intranet-workflow/sql/postgresql/upgrade/upgrade-3.4.0.0.0-3.4.0.1.0.sql

create or replace function inline_1 ()
returns integer as '
       DECLARE
        	v_object_id		integer;
        	v_count			integer;
        BEGIN
        	-- Get the Main Site id, used as the global identified for permissions
        	select package_id into v_object_id from apm_packages
        	where package_key=''acs-subsite'';
        
        	select count(*) into v_count from acs_permissions
        	where object_id = v_object_id and grantee_id = 771 and privilege = ''wf_reassign_tasks'';
        	IF v_count = 0 THEN return 0; end if;
        
        	PERFORM acs_permission__revoke_permission(v_object_id, 471, ''wf_reassign_tasks'');
       
        	return 0;
	END;' language 'plpgsql';
select inline_1 ();
drop function inline_1();


# create menu "Rechnung auf Basis Kunden/Mitarbeiter Preisliste anlegen"
create or replace function inline_1 ()
returns integer as '
declare
        v_menu                  integer;
        v_parent_menu           integer;
        v_senior_managers       integer;
        v_project_managers      integer;
begin
        select group_id into v_project_managers from groups where group_name = ''Project Managers'';
        select group_id into v_senior_managers from groups where group_name = ''Senior Managers'';

        select menu_id into v_parent_menu from im_menus where label = ''invoices_customers'';

        v_menu := im_menu__new (
                null,                                           -- p_menu_id
                ''im_menu'',                                    -- object_type
                now(),                                          -- creation_date
                null,                                           -- creation_user
                null,                                           -- creation_ip
                null,                                           -- context_id
                ''intranet-cust-koernigweber'',                 -- package_name
                ''invoices_customer_employee_prices'',          -- label
                ''Rechnung auf Basis Kunden/Mitarbeiter Preisliste anlegen'',   -- name
                ''/intranet-cust-koernigweber/invoices/new?target_cost_type_id=3700'', -- url
                500,                                            -- sort_order
                v_parent_menu,                                  -- parent_menu_id
                ''[im_cost_type_write_p $user_id 3700]''        -- p_visible_tcl
        );

        PERFORM acs_permission__grant_permission(v_menu, v_project_managers, ''read'');
        PERFORM acs_permission__grant_permission(v_menu, v_senior_managers, ''read'');

        return 0;
end;' language 'plpgsql';
select inline_1 ();
drop function inline_1();



select acs_privilege__create_privilege('admin_company_price_matrix','Admin Company Price Matrix','Admin Company Price Matrix');
select acs_privilege__add_child('admin', 'admin_company_price_matrix');

select im_priv_create('admin_company_price_matrix', 'Accounting');
select im_priv_create('admin_company_price_matrix', 'P/O Admins');
select im_priv_create('admin_company_price_matrix', 'Senior Managers');


-- Absences 
alter table im_user_absences add column absence_day_p  char(1); 
alter table im_user_absences add column duration_hours numeric(12,1);


create or replace function im_cust_kw_workflow__remove_log_blocking(int4, text) returns int4 as '
 declare
        p_task_id               alias for $1;
        p_custom_arg            alias for $2;

        v_transition_key        varchar;
        v_object_type           varchar;
        v_case_id               integer;
        v_object_id             integer;
        v_creation_user         integer;
        v_creation_ip           varchar;
        v_project_manager_id    integer;
        v_project_manager_name  varchar;

        v_journal_id            integer;

 begin
        -- Get information about the transition and the ''environment''
        select  tr.transition_key, t.case_id, c.object_id, o.creation_user, o.creation_ip, o.object_type
        into    v_transition_key, v_case_id, v_object_id, v_creation_user, v_creation_ip, v_object_type
        from    wf_tasks t, wf_cases c, wf_transitions tr, acs_objects o
        where   t.task_id = p_task_id
                and t.case_id = c.case_id
                and o.object_id = t.case_id
                and t.workflow_key = tr.workflow_key
                and t.transition_key = tr.transition_key;

        update im_hours set conf_object_id = NULL where conf_object_id in (select object_id from wf_cases where case_id = v_case_id);

        return 0;
end;' language 'plpgsql';
 
create or replace function im_cust_kw_workflow__remove_log_blocking(int4, text, text) returns int4 as '
 declare
        p_task_id               alias for $1;
        p_custom_arg            alias for $2;
        p_custom_arg_1          alias for $3;	

        v_transition_key        varchar;
        v_object_type           varchar;
        v_case_id               integer;
        v_object_id             integer;
        v_creation_user         integer;
        v_creation_ip           varchar;
        v_project_manager_id    integer;
        v_project_manager_name  varchar;

        v_journal_id            integer;

 begin
        -- Get information about the transition and the ''environment''
        -- select  tr.transition_key, t.case_id, c.object_id, o.creation_user, o.creation_ip, o.object_type
        -- into    v_transition_key, v_case_id, v_object_id, v_creation_user, v_creation_ip, v_object_type
        -- from    wf_tasks t, wf_cases c, wf_transitions tr, acs_objects o
        -- where   t.task_id = p_task_id
        --        and t.case_id = c.case_id
        --        and o.object_id = t.case_id
        --        and t.workflow_key = tr.workflow_key
        --        and t.transition_key = tr.transition_key;

	RAISE NOTICE ''im_cust_kw_workflow__remove_log_blocking:alias_1 =%, alias_2 =%, alias3 =%, v_case_id=%'', p_task_id, p_custom_arg, p_custom_arg_1, v_case_id;
	update im_hours set conf_object_id = NULL where conf_object_id in (select object_id from wf_cases where case_id = p_task_id); 

        return 0;
end;' language 'plpgsql';


-- -------------------------------------------------------------
-- Hours/Minutes for absences 
-- -------------------------------------------------------------

ALTER TABLE im_user_absences ALTER COLUMN duration_days TYPE numeric(12,5);
ALTER TABLE im_user_absences ADD COLUMN hours_day_base numeric(2,1);

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for) values (20015,200,NULL,'Days','"[lindex [split [calculate_dd_hh_mm_from_day $duration_days $hours_day_base] \" \"] 0 ]"','','',12,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for) values (20016,200,NULL,'Hours','"[lindex [split [calculate_dd_hh_mm_from_day $duration_days $hours_day_base] \" \"] 1 ]"','','',13,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for) values (20017,200,NULL,'Minutes','"[expr [lindex [split [calculate_dd_hh_mm_from_day $duration_days $hours_day_base] \" \"] 2 ]*15]"','','',14,'');
