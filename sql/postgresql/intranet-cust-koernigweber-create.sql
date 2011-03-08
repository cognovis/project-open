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

select acs_object_type__create_type (
        'project_approval2_wf',           -- object_type
        'Project Close Approval',              -- pretty_name
        'Project Close Approval',            -- pretty_plural
        'workflow',        -- supertype
        'project_approval2_wf_cases',         -- table_name
        'case_id',           -- id_column
        'project_approval2_wf',           -- package_name
        'f',                    -- abstract_p
        null,                   -- type_extension_table
        'null'      -- name_method
);

insert into acs_object_type_tables (object_type,table_name,id_column) values ('project_approval2_wf', 'project_approval2_wf_cases', 'case_id');


create or replace function im_workflow__assign_to_project_manager(int4, text) returns int4 as '
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

	IF v_object_type = ''timesheet_approval_wf'' THEN
 		select  project_lead_id into v_project_manager_id from im_projects
		where   project_id in (select conf_project_id from im_timesheet_conf_objects where conf_id = v_object_id);		
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
end;' language 'plpgsql';


-- create table to manage Employee/Customer Price Matrix 

create table im_emp_cust_price_list (
        id                      integer
                                primary key,
        user_id			integer
				constraint im_employee_customer_price_list_user_fk
                                references users,
        company_id              integer not null
                                constraint im_employee_customer_price_list_company_fk 
				references im_companies,
        amount                  numeric(12,2),
        currency                char(3)
                                constraint im_costs_currency_fk
                                references currency_codes(iso),
	unique(user_id, company_id)
);

create index emp_cust_price_list_idx on im_emp_cust_price_list(id);

select acs_object_type__create_type (
        'im_employee_customer_price',           -- object_type
        'Employee Customer Price',              -- pretty_name
        'Employee Customer Price',             	-- pretty_plural
        'im_biz_object',        		-- supertype
        'im_emp_cust_price_list',      		-- table_name
        'id',           			-- id_column
        'im_emp_cust_price_list',      		-- package_name
        'f',                  			-- abstract_p
        null,                  			-- type_extension_table
        'im_emp_cust_price__name'      		-- name_method
);

insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_employee_customer_price', 'im_emp_cust_price_list', 'id');

-- check if required
-- update acs_object_types set
--        status_type_table = 'im_projects',
--        status_column = 'project_status_id',
--        type_column = 'project_type_id'
-- where object_type = 'im_project';

create or replace function im_employee_customer_price__update(int4,varchar,timestamptz,int4,varchar,int4,int,int,numeric,varchar) returns int4 as '
        DECLARE
                p_id              alias for $1;
                p_object_type     alias for $2;
                p_creation_date   alias for $3;
                p_creation_user   alias for $4;
                p_creation_ip     alias for $5;
                p_context_id      alias for $6;

                p_user_id         alias for $7;
                p_company_id      alias for $8;
                p_amount          alias for $9;
                p_currency        alias for $10;
                v_id              integer;
                v_count           integer;
        BEGIN
                select count(*) into v_count from im_emp_cust_price_list where user_id = p_user_id and company_id = p_company_id;
                IF v_count > 0 THEN
                        update im_emp_cust_price_list set amount = p_amount where company_id = p_company_id and user_id = p_user_id;
                ELSE
                        v_id := acs_object__new (
                                p_id,
                                p_object_type,
                                p_creation_date,
                                p_creation_user,
                                p_creation_ip,
                                p_context_id
                        );

                        insert into im_emp_cust_price_list (
                                id, user_id, company_id, amount, currency
                        ) values (
                                v_id, p_user_id, p_company_id, p_amount, p_currency
                        );
                END IF;
                return v_id;
end;' language 'plpgsql';


-- Create a plugin for the ProjectViewPage.
SELECT im_component_plugin__new (
        null,                           -- plugin_id
        'im_component_plugin',          -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Employee Customer Price List', -- plugin_name
        'intranet-cust-koernigweber',   -- package_name
        'right',                        -- location
        '/intranet/companies/view',     -- page_url
        null,                           -- view_name
        15,                             -- sort_order
        'im_group_member_component_employee_customer_price_list $company_id $user_id 0 $return_url "" "" $also_add_to_group' -- component_tcl
);

update im_component_plugins
set title_tcl = 'lang::message::lookup "" intranet-cust-koernigweber.TitlePortletEmployeeCustomerPriceList "Employee/Customer Price List"'
where plugin_name = 'Employee/Customer Price List';


SELECT im_lang_add_message('de_DE','intranet-cust-koernigweber','Mail_Reminder_Log_Hours','Erinnerung:\n Bitte erfassen Sie Ihre Stunden und erteilen Sie die Freigabe\n Mit freundlichen Gr&uumlssen;\n %current_user_name%');
