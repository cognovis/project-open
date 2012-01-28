-- /packages/intranet-customer-portal/sql/postgres/intranet-customer-portal-create.sql
--
-- Copyright (C) 2011-2012 ]project-open[ 
--
-- This program is free software. You can redistribute it
-- and/or modify it under the terms of the GNU General
-- Public License as published by the Free Software Foundation;
-- either version 2 of the License, or (at your option)
-- any later version. This program is distributed in the
-- hope that it will be useful, but WITHOUT ANY WARRANTY;
-- without even the implied warranty of MERCHANTABILITY or
-- FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details.
--
-- @author klaus.hofeditz@project-open.com

-- Create table for inquiries 

create sequence im_inquiries_customer_portal_seq start 1;
create table im_inquiries_customer_portal (
        inquiry_id              integer
                                primary key,
        user_id 	        integer,
        first_names             varchar(50),
        last_names              varchar(80),
	title			varchar(80),
        email	                varchar(50),
        company_name            varchar(80),
        phone			varchar(20),
        security_token 		varchar(40),
	company_id		integer,
	status_id		integer,
	session_id		varchar(200),
	project_id		integer,
	inquiry_date		date,
	comment			varchar(1000)
);


create sequence im_inquiries_files_seq start 1;
create table im_inquiries_files (
        inquiry_files_id        integer
                                primary key,
        inquiry_id              integer,
        file_name               varchar(50)
                                not null,
	source_language 	varchar(4) 
                                not null,
	target_languages	varchar(200)
                                not null, 
	deliver_date		date,
	project_id		integer,
	file_path		varchar(200)
);

-- Create DynView for project list  

delete from im_view_columns where view_id = 960; 
delete from im_views where view_id = 960; 

insert into im_views (view_id, view_name, visible_for, view_type_id)
values (960, 'project-list-customer-portal', 'view_projects', 1415);

CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS INTEGER AS '
declare
        v_count                 integer;
begin
	select column_id+1 into v_count from im_view_columns order by column_id desc limit 1;

	insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
	extra_select, extra_where, sort_order, visible_for, ajax_configuration) values (v_count,960,NULL,''[lang::message::lookup "" intranet-core.Project "Project"]'',
	''project_name'','''','''',1,'''', ''def '');

        return 1;

end;' LANGUAGE 'plpgsql';
SELECT inline_0 ();
DROP FUNCTION inline_0 ();

SELECT  im_component_plugin__new (
        null,       	             -- plugin_id
        'acs_object',                -- object_type
        now(),                       -- creation_date
        null,                        -- creation_user
        null,                        -- creation_ip
        null,                           -- context_id
        'Requests for Quote',		-- plugin_name
        'intranet-customer-portal',     -- package_name
        'right',                        -- location
        '/intranet/index',              -- page_url
        null,                           -- view_name
        1,                              -- sort_order
        'im_list_rfqs_component'  	-- component_tcl
);


SELECT  im_component_plugin__new (
        null,                        -- plugin_id
        'acs_object',                -- object_type
        now(),                       -- creation_date
        null,                        -- creation_user
        null,                        -- creation_ip
        null,                           -- context_id
        'Financial Documents',          -- plugin_name
        'intranet-customer-portal',     -- package_name
        'right',                          -- location
        '/intranet/index',              -- page_url
        null,                           -- view_name
        1,                              -- sort_order
        'im_list_financial_documents_component'        -- component_tcl
);



-- Set permissions on all Plugin Components for Employees, Freelancers and Customers.
create or replace function inline_0 ()
returns varchar as '
DECLARE
        v_count         integer;
        v_plugin_id     integer;
        row             RECORD;

        v_emp_id        integer;
        v_freel_id      integer;
        v_cust_id       integer;
	v_pm_id		integer;
BEGIN
        select group_id into v_emp_id from groups where group_name = ''Employees'';
        select group_id into v_freel_id from groups where group_name = ''Freelancers'';
        select group_id into v_cust_id from groups where group_name = ''Customers'';
        select group_id into v_pm_id from groups where group_name = ''Project Managers'';

        -- Add read permissions to - Requests for Quote -

        select  plugin_id
	into 	v_plugin_id
        from    im_component_plugins pl
	where   plugin_name = ''Requests for Quote''
		and package_name = ''intranet-customer-portal'';

        PERFORM im_grant_permission(v_plugin_id, v_pm_id, ''read'');
        PERFORM im_grant_permission(v_plugin_id, v_cust_id, ''read'');

        -- Add read permissions to - Financial Documents -

        select  plugin_id
        into    v_plugin_id
        from    im_component_plugins pl
        where   plugin_name = ''Financial Documents'' 
		and package_name = ''intranet-customer-portal'';

        PERFORM im_grant_permission(v_plugin_id, v_cust_id, ''read'');

        return 0;
END;' language 'plpgsql';
select inline_0();
drop function inline_0();

-- create new Category to 
SELECT im_category_new ('380', 'Quote accepted', 'Intranet Project Status');



-- create function that assigns PM to project

create or replace function im_customer_portal_assign_pm(int4,text, text) returns int4 as '
        declare
                p_case_id               alias for $1;
                p_transition_key        alias for $2;
                p_custom_arg            alias for $3;
        
        	v_task_id		integer;	v_case_id		integer;
        	v_creation_ip		varchar; 	v_creation_user		integer;
        	v_object_id		integer;	v_object_type		varchar;
        	v_journal_id		integer;
        	v_transition_key	varchar;	v_workflow_key		varchar;
               	v_group_id		integer;	v_group_name		varchar;
		v_task_owner		integer;
        begin
        	-- Select out some frequently used variables of the environment
        	select	c.object_id, c.workflow_key, task_id, c.case_id, co.object_type, co.creation_ip
        	into	v_object_id, v_workflow_key, v_task_id, v_case_id, v_object_type, v_creation_ip
        	from	wf_tasks t, wf_cases c, acs_objects co
        	where	c.case_id = p_case_id
        		and c.case_id = co.object_id
        		and t.case_id = c.case_id
        		and t.workflow_key = c.workflow_key
        		and t.transition_key = p_transition_key;

		-- set PM to 
		select 
			creation_user 
		into 
			v_task_owner 
		from 
			acs_objects 
		where 
			object_id = (select journal_id from journal_entries where object_id=v_case_id and action_pretty = ''Create quote finish'') and
			object_type = ''journal_entry'';

		update im_projects set project_lead_id = v_task_owner where project_id = v_object_id;    

                -- IF v_group_id is not null THEN
                --      v_journal_id := journal_entry__new(
                --          null, v_case_id,
                --          v_transition_key || '' assign_to_user '' || v_group_name,
                --          v_transition_key || '' assign_to_user '' || v_group_name,
                --          now(), v_creation_user, v_creation_ip,
                --          ''Setting Project Manager'' || v_task_owner
                --      );
                -- END IF;
                return 0;
	end;
' language 'plpgsql';


create or replace function inline_1 ()
returns integer as '
declare
        v_menu                  integer;
        v_parent_menu           integer;
        v_customers             integer;
begin
        select group_id into v_customers from groups where group_name = ''Customers'';

        select menu_id into v_parent_menu
        from im_menus where label = ''main'';

        v_menu := im_menu__new (
                null,                                   -- p_menu_id
                ''im_menu'',                            -- object_type
                now(),                                  -- creation_date
                null,                                   -- creation_user
                null,                                   -- creation_ip
                null,                                   -- context_id
                ''intranet-customer-portal'',  		-- package_name
                ''intranet_customer_portal'', 		-- label
                ''Request for Quote'',      		-- name
                ''/intranet-customer-portal/upload-files'',   -- url
                900,                                    -- sort_order
                v_parent_menu,                          -- parent_menu_id
                null                                    -- p_visible_tcl
        );

        PERFORM acs_permission__grant_permission(v_menu, v_customers, ''read'');
        return 0;
end;' language 'plpgsql';
select inline_1 ();
drop function inline_1();



-- creating wf notification 

CREATE OR REPLACE FUNCTION im_customer_portal_notify_customer(integer, varchar, varchar)
  RETURNS integer AS '

declare
        p_case_id               alias for $1;
        p_transition_key        alias for $2;
	p_custom_arg            alias for $3;

        v_task_id               integer;        v_case_id               integer;
        v_creation_ip           varchar;        v_creation_user         integer;
        v_object_id             integer;        v_object_type           varchar;
        v_journal_id            integer;
        v_transition_key        varchar;        v_workflow_key          varchar;
        v_group_id              integer;        v_group_name            varchar;
        v_task_owner            integer;

        v_object_name           text;
        v_party_from            parties.party_id%TYPE;
        v_party_to              parties.party_id%TYPE;
        v_subject               text;
        v_body                  text;
        v_request_id            integer;

        v_locale                text;
        v_count                 integer;

begin
        RAISE NOTICE ''KHD: Notify_assignee_project_approval: enter'';

        -- Select out some frequently used variables of the environment
        select  c.object_id, c.workflow_key, co.creation_user, task_id, c.case_id, co.object_type, co.creation_ip
        into    v_object_id, v_workflow_key, v_creation_user, v_task_id, v_case_id, v_object_type, v_creation_ip
        from    wf_tasks t, wf_cases c, acs_objects co
        where   c.case_id = p_case_id
                and c.case_id = co.object_id
                and t.case_id = c.case_id
                and t.workflow_key = c.workflow_key
                and t.transition_key = p_transition_key;

        v_party_from := -1;

        -- Get locale of user
        select  language_preference into v_locale
        from    user_preferences
        where   user_id = v_creation_user;

        -- ------------------------------------------------------------
        -- Try with specific translation first
        v_subject := ''Notification_Subject_Notify_Customer_Quote_Created'';
        v_subject := acs_lang_lookup_message(v_locale, ''intranet-customer-portal'', v_subject);

        -- Fallback to generic (no transition key) translation
        IF substring(v_subject from 1 for 7) = ''MISSING'' THEN
                v_subject := ''A quote has been created'';
        END IF;

        -- Replace variables
        -- v_subject := replace(v_subject, ''%object_name%'', v_object_name);
        -- v_subject := replace(v_subject, ''%transition_name%'', v_transition_name);

        -- ------------------------------------------------------------
        -- Try with specific translation first
        v_body := ''Notification_Body_Notify_Customer_QuoteCreated'';
        v_body := acs_lang_lookup_message(v_locale, ''intranet-customer-portal'', v_body);

        -- Fallback to generic (no transition key) translation
        IF substring(v_body from 1 for 7) = ''MISSING'' THEN
                v_body := ''Please check your RFQ box for a new quote'';
        END IF;
        -- Replace variables
        -- v_body := replace(v_body, ''%object_name%'', v_object_name);
        -- v_body := replace(v_body, ''%transition_name%'', v_transition_name);

        RAISE NOTICE ''KHD: Notify_assignee_project_approval: Subject=%, Body=%'', v_subject, v_body;

        v_request_id := acs_mail_nt__post_request (
		v_party_from,                 -- party_from
		v_creation_user,              -- party_to
		''f'',                        -- expand_group
		v_subject,                    -- subject
		v_body,                       -- message
		0                             -- max_retries
        );

        return 0;
end;
' LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION im_customer_portal_notify_pm(integer, varchar, varchar)
  RETURNS integer AS '

declare
        p_case_id               alias for $1;
        p_transition_key        alias for $2;
	p_custom_arg            alias for $3;

        v_task_id               integer;        v_case_id               integer;
        v_creation_ip           varchar;        v_creation_user         integer;
        v_object_id             integer;        v_object_type           varchar;
        v_journal_id            integer;
        v_transition_key        varchar;        v_workflow_key          varchar;
        v_group_id              integer;        v_group_name            varchar;
        v_task_owner            integer;

        v_object_name           text;
        v_party_from            parties.party_id%TYPE;
        v_party_to              parties.party_id%TYPE;
        v_subject               text;
        v_body                  text;
        v_request_id            integer;

	v_pm 			integer; 
        v_locale                text;
        v_count                 integer;


begin
        RAISE NOTICE ''KHD: Notify_assignee_project_approval: enter'';

        -- Select out some frequently used variables of the environment
        select  c.object_id, c.workflow_key, co.creation_user, task_id, c.case_id, co.object_type, co.creation_ip
        into    v_object_id, v_workflow_key, v_creation_user, v_task_id, v_case_id, v_object_type, v_creation_ip
        from    wf_tasks t, wf_cases c, acs_objects co
        where   c.case_id = p_case_id
                and c.case_id = co.object_id
                and t.case_id = c.case_id
                and t.workflow_key = c.workflow_key
                and t.transition_key = p_transition_key;

        v_party_from := -1;

	-- get Project Manager id  
	select project_lead_id into v_pm from im_projects where project_id = v_object_id;

        -- Get locale of PM
        select  language_preference into v_locale
        from    user_preferences
        where   user_id = v_pm;

        -- ------------------------------------------------------------
        -- Try with specific translation first
        v_subject := ''Notification_Subject_Notify_Project_Customer_Decision'';
        v_subject := acs_lang_lookup_message(v_locale, ''intranet-customer-portal'', v_subject);

        -- Fallback to generic (no transition key) translation
        IF substring(v_subject from 1 for 7) = ''MISSING'' THEN
                v_subject := ''RFQ: Customer decision taken'';
        END IF;

        -- Replace variables
        -- v_subject := replace(v_subject, ''%object_name%'', v_object_name);
        -- v_subject := replace(v_subject, ''%transition_name%'', v_transition_name);

        -- ------------------------------------------------------------
        -- Try with specific translation first
        v_body := ''Notification_Body_Notify_Project_Customer_Decision'';
        v_body := acs_lang_lookup_message(v_locale, ''intranet-customer-portal'', v_body);

        -- Fallback to generic (no transition key) translation
        IF substring(v_body from 1 for 7) = ''MISSING'' THEN
                v_body := ''Customer rejected/accepted Quote'';
        END IF;
        -- Replace variables
        -- v_body := replace(v_body, ''%object_name%'', v_object_name);
        -- v_body := replace(v_body, ''%transition_name%'', v_transition_name);

        RAISE NOTICE ''KHD: Notify_assignee_project_approval: Subject=%, Body=%'', v_subject, v_body;

        v_request_id := acs_mail_nt__post_request (
		v_party_from,                 -- party_from
		v_pm,		              -- party_to
		''f'',                        -- expand_group
		v_subject,                    -- subject
		v_body,                       -- message
		0                             -- max_retries
        );

        return 0;
end;
' LANGUAGE 'plpgsql';




/*
 * Business Process Definition: Process RFQ (rfq_customer_portal_wf)
 *
 * Auto-generated by ACS Workflow Export, version 4.3
 *
 * Context: default
 */


/*
 * Cases table
 */
create table rfq_customer_portal_wf_cases (
  case_id               integer primary key
                        references wf_cases on delete cascade
);

/* 
 * Declare the object type
 */


create function inline_0 () returns integer as '
begin
    PERFORM workflow__create_workflow (
        ''rfq_customer_portal_wf'', 
        ''Process RFQ'', 
        ''Process RFQ'', 
        ''Default WF for RFQs'', 
        ''rfq_customer_portal_wf_cases'',
        ''case_id''
    );

    return null;

end;' language 'plpgsql';

select inline_0 ();
drop function inline_0 ();

        


/*****
 * Places
 *****/


    select workflow__add_place(
        'rfq_customer_portal_wf',
        'start', 
        'Ready to Modify', 
        null
    );

        

    select workflow__add_place(
        'rfq_customer_portal_wf',
        'before_approve', 
        'Ready to Approve', 
        null
    );

        

    select workflow__add_place(
        'rfq_customer_portal_wf',
        'end', 
        'Process finished', 
        null
    );

        

    select workflow__add_place(
        'rfq_customer_portal_wf',
        'waiting_for_customer_decision', 
        'Waiting for Customer Decision', 
        null
    );

        

    select workflow__add_place(
        'rfq_customer_portal_wf',
        'quote_rejected', 
        'Quote rejected', 
        null
    );

        

    select workflow__add_place(
        'rfq_customer_portal_wf',
        'decision_made', 
        'Quote accepted', 
        null
    );

        
/*****
 * Roles
 *****/



	select workflow__add_role (
         'rfq_customer_portal_wf',
         'modify',
         'Modify',
         1
    );

        

	select workflow__add_role (
         'rfq_customer_portal_wf',
         'approve',
         'Approve',
         2
    );

        

	select workflow__add_role (
         'rfq_customer_portal_wf',
         'approved',
         'Approved',
         3
    );

        

	select workflow__add_role (
         'rfq_customer_portal_wf',
         'deleted',
         'Deleted',
         4
    );

        

/*****
 * Transitions
 *****/



	select workflow__add_transition (
         'rfq_customer_portal_wf',
         'modify',
         'Modify',
         'modify',
         1,
         'user'
	);
	
        

	select workflow__add_transition (
         'rfq_customer_portal_wf',
         'approve',
         'Create quote',
         'approve',
         2,
         'user'
	);
	
        

	select workflow__add_transition (
         'rfq_customer_portal_wf',
         'rfq_accepted',
         'Waiting for Client decision',
         'modify',
         3,
         'user'
	);
	
        

	select workflow__add_transition (
         'rfq_customer_portal_wf',
         'quote_rejected',
         'Quote rejected',
         'modify',
         4,
         'automatic'
	);
	
        

	select workflow__add_transition (
         'rfq_customer_portal_wf',
         'quote_accepted',
         'Quote accepted',
         'modify',
         5,
         'automatic'
	);
	
        

/*****
 * Arcs
 *****/



	select workflow__add_arc (
         'rfq_customer_portal_wf',
         'approve',
         'start',
         'out',
         '#',
         '',
         'Projekt abgelehnt'
	);

        

	select workflow__add_arc (
         'rfq_customer_portal_wf',
         'approve',
         'before_approve',
         'in',
         '',
         '',
         ''
	);

        

	select workflow__add_arc (
         'rfq_customer_portal_wf',
         'approve',
         'waiting_for_customer_decision',
         'out',
         '',
         '',
         ''
	);

        

	select workflow__add_arc (
         'rfq_customer_portal_wf',
         'modify',
         'start',
         'in',
         '',
         '',
         ''
	);

        

	select workflow__add_arc (
         'rfq_customer_portal_wf',
         'modify',
         'before_approve',
         'out',
         '',
         '',
         ''
	);

        

	select workflow__add_arc (
         'rfq_customer_portal_wf',
         'quote_accepted',
         'decision_made',
         'in',
         '',
         '',
         ''
	);

        

	select workflow__add_arc (
         'rfq_customer_portal_wf',
         'quote_accepted',
         'end',
         'out',
         '',
         '',
         ''
	);

        

	select workflow__add_arc (
         'rfq_customer_portal_wf',
         'quote_rejected',
         'end',
         'out',
         '',
         '',
         ''
	);

        

	select workflow__add_arc (
         'rfq_customer_portal_wf',
         'quote_rejected',
         'quote_rejected',
         'in',
         '',
         '',
         ''
	);

        

	select workflow__add_arc (
         'rfq_customer_portal_wf',
         'rfq_accepted',
         'quote_rejected',
         'out',
         '#',
         '',
         'Quote rejected'
	);

        

	select workflow__add_arc (
         'rfq_customer_portal_wf',
         'rfq_accepted',
         'decision_made',
         'out',
         '',
         '',
         'Quote accepted'
	);

        

	select workflow__add_arc (
         'rfq_customer_portal_wf',
         'rfq_accepted',
         'waiting_for_customer_decision',
         'in',
         '',
         '',
         ''
	);

        

/*****
 * Attributes
 *****/



    select workflow__create_attribute(
        'rfq_customer_portal_wf',
        'client_decision',
        'boolean',
        'Quote accepted by client?',
	null,
	null,
	null,
        '',
	1,
	1,
	null,
	'generic'
    );

        

	select workflow__add_trans_attribute_map(
        	'rfq_customer_portal_wf', 
        	'rfq_accepted',
        	'client_decision',
        	1
    );

        

    select workflow__create_attribute(
        'rfq_customer_portal_wf',
        'approve_approve_this_project_bundle_p',
        'boolean',
        'Quote created?',
	null,
	null,
	null,
        't',
	1,
	1,
	null,
	'generic'
    );

        

	select workflow__add_trans_attribute_map(
        	'rfq_customer_portal_wf', 
        	'approve',
        	'approve_approve_this_project_bundle_p',
        	1
    );

        
/*****
 * Transition-role-assignment-map
 *****/



/*
 * Context/Transition info
 * (for context = default)
 */

insert into wf_context_transition_info
(context_key,
 workflow_key,
 transition_key,
 estimated_minutes,
 instructions,
 enable_callback,
 enable_custom_arg,
 fire_callback,
 fire_custom_arg,
 time_callback,
 time_custom_arg,
 deadline_callback,
 deadline_custom_arg,
 deadline_attribute_name,
 hold_timeout_callback,
 hold_timeout_custom_arg,
 notification_callback,
 notification_custom_arg,
 unassigned_callback,
 unassigned_custom_arg)
values
('default',
 'rfq_customer_portal_wf',
 'quote_rejected',
 null,
 '',
 '',
 '',
 'im_workflow__set_object_status_id',
 '77',
 '',
 '',
 '',
 '',
 '',
 '',
 '',
 '',
 '',
 '',
 '');

insert into wf_context_transition_info
(context_key,
 workflow_key,
 transition_key,
 estimated_minutes,
 instructions,
 enable_callback,
 enable_custom_arg,
 fire_callback,
 fire_custom_arg,
 time_callback,
 time_custom_arg,
 deadline_callback,
 deadline_custom_arg,
 deadline_attribute_name,
 hold_timeout_callback,
 hold_timeout_custom_arg,
 notification_callback,
 notification_custom_arg,
 unassigned_callback,
 unassigned_custom_arg)
values
('default',
 'rfq_customer_portal_wf',
 'quote_accepted',
 null,
 '',
 '',
 '',
 'im_workflow__set_object_status_id',
 '76',
 '',
 '',
 '',
 '',
 '',
 '',
 '',
 '',
 '',
 '',
 '');

insert into wf_context_transition_info
(context_key,
 workflow_key,
 transition_key,
 estimated_minutes,
 instructions,
 enable_callback,
 enable_custom_arg,
 fire_callback,
 fire_custom_arg,
 time_callback,
 time_custom_arg,
 deadline_callback,
 deadline_custom_arg,
 deadline_attribute_name,
 hold_timeout_callback,
 hold_timeout_custom_arg,
 notification_callback,
 notification_custom_arg,
 unassigned_callback,
 unassigned_custom_arg)
values
('default',
 'rfq_customer_portal_wf',
 'rfq_accepted',
 null,
 '',
 'im_customer_portal_assign_pm',
 '',
 'im_customer_portal_notify_pm',
 '',
 '',
 '',
 '',
 '',
 '',
 '',
 '',
 '',
 '',
 '',
 '');

insert into wf_context_transition_info
(context_key,
 workflow_key,
 transition_key,
 estimated_minutes,
 instructions,
 enable_callback,
 enable_custom_arg,
 fire_callback,
 fire_custom_arg,
 time_callback,
 time_custom_arg,
 deadline_callback,
 deadline_custom_arg,
 deadline_attribute_name,
 hold_timeout_callback,
 hold_timeout_custom_arg,
 notification_callback,
 notification_custom_arg,
 unassigned_callback,
 unassigned_custom_arg)
values
('default',
 'rfq_customer_portal_wf',
 'modify',
 5,
 '',
 '',
 '',
 '',
 '',
 '',
 '',
 '',
 '',
 '',
 '',
 '',
 '',
 '',
 'im_workflow__assign_to_group',
 'Project Managers');

insert into wf_context_transition_info
(context_key,
 workflow_key,
 transition_key,
 estimated_minutes,
 instructions,
 enable_callback,
 enable_custom_arg,
 fire_callback,
 fire_custom_arg,
 time_callback,
 time_custom_arg,
 deadline_callback,
 deadline_custom_arg,
 deadline_attribute_name,
 hold_timeout_callback,
 hold_timeout_custom_arg,
 notification_callback,
 notification_custom_arg,
 unassigned_callback,
 unassigned_custom_arg)
values
('default',
 'rfq_customer_portal_wf',
 'approve',
 5,
 '',
 '',
 '',
 'im_customer_portal_notify_customer',
 '',
 '',
 '',
 '',
 '',
 '',
 '',
 '',
 '',
 '',
 'im_workflow__assign_to_group',
 'Project Managers');



/*
 * Context/Role info
 * (for context = default)
 */



/*
 * Context Task Panels
 * (for context = default)
 */

insert into wf_context_task_panels 
(context_key,
 workflow_key,
 transition_key,
 sort_order,
 header,
 template_url,
 overrides_action_p,
 overrides_both_panels_p,
 only_display_when_started_p)
values
('default',
 'rfq_customer_portal_wf',
 'approve',
 1,
 'Create Quote',
 '/packages/intranet-customer-portal/www/panel-rfq',
 'f',
 'f',
 'f');


commit;

