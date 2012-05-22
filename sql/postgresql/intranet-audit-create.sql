-- /packages/intranet-audit/sql/postgresql/intranet-audit-create.sql
--
-- Copyright (c) 2007 ]project-open[
--
-- All rights including reserved. To inquire license terms please 
-- refer to http://www.project-open.com/modules/<module-key>

-- ----------------------------------------------------------------
-- intranet-audit
--
-- Keeps track of 
-- ----------------------------------------------------------------

create sequence im_audit_seq;

create table im_audits (
	audit_id		integer
				constraint im_audits_pk
				primary key,
	audit_object_id		integer
				constraint im_audits_object_nn
				not null,
	audit_object_status_id	integer,
	audit_action		text
				constraint im_audits_action_ck
				check (audit_action in ('after_create','before_update','after_update','before_nuke', 'baseline')),
	audit_user_id		integer
				constraint im_audits_user_nn
				not null,
	audit_date		timestamptz
				constraint im_audits_date_nn
				not null,
	audit_ip		varchar(50)
				constraint im_audits_ip_nn
				not null,
	audit_last_id		integer
				constraint im_audits_last_fk
				references im_audits,
	audit_ref_object_id	integer,
	audit_value		text
				constraint im_audits_value_nn
				not null,
	audit_diff		text,
	audit_note		text,
	audit_hash		text
);

-- Add a link for every object to the ID of the last audit entry
alter table acs_objects add column last_audit_id integer;

-- Add a foreign key constraint on last_audit_id:
alter table acs_objects 
add constraint acs_objects_last_audit_id_fkey 
foreign key (last_audit_id) references im_audits;

-- Create an index for fast access of the changes of an object
create index im_audits_audit_object_id_idx on im_audits(audit_object_id);

-- Create an index for fast access of the audit date
create index im_audits_audit_date_idx on im_audits(audit_date);

comment on table im_audits is '
 Generic audit table. A new row is created everytime that the value
 of the object is updated.
';

comment on column im_audits.audit_id is '
 ID of the audit log (not an OpenACS object_id).
';

comment on column im_audits.audit_object_id is '
 Object to be audited.
';

comment on column im_audits.audit_action is '
 Type of action - one of create, update, delete, nuke or pre_update.
';

comment on column im_audits.audit_user_id is '
 Who has performed the change?
';

comment on column im_audits.audit_date is '
 When was the change performed?
';

comment on column im_audits.audit_ip is '
 IP address of the connection initiating the change.
';

comment on column im_audits.audit_last_id is '
 Pointer to the last last audit of the object or NULL
 before the first update. Used to quickly find the old
 values for calculating a diff.
';

comment on column im_audits.audit_ref_object_id is '
 Optional reference to an object who initiated the change.
';

comment on column im_audits.audit_value is '
 List of the object fields after the update.
';

comment on column im_audits.audit_diff is '
 Difference between the audit_value of the audit_value
 of the audit_last_id and the new audit_value.
';

comment on column im_audits.audit_note is '
 Additional note by the user. Optional.
';

comment on column im_audits.audit_hash is '
 Crypto hash to ensure the integrity of the audit log.
 The hash value includes the hash of the audit_last_id,
 so that any modification in the audit log can be 
 identified.
 In the case of a complete recalculation of all hashs,
 the PostgreSQL OIDs will witness these changes.
';


-------------------------------------------------------------
-- Audit for im_projects
--
-- The table and audit trigger definition will in future be
-- defined by the intranet-dynfield module to take care of
-- dynamic extensions of data types

create table im_projects_audit (
	audit_id			integer,
        modifying_action		varchar(20),
        last_modified			timestamptz,
        last_modifying_user		integer,
	last_modifying_ip		varchar(50),

	project_id			integer,
	project_name			text,
	project_nr			text,
	project_path			text,
	parent_id			integer,
	company_id			integer,
	project_type_id			integer,
	project_status_id		integer,
	description			text,
	billing_type_id			integer,
	note				text,
	project_lead_id			integer,
	supervisor_id			integer,
	project_budget			float,
	corporate_sponsor		integer,
	percent_completed		float,
	on_track_status_id		integer,
	project_budget_currency		character(3),
	project_budget_hours		float,
	end_date			timestamptz,
	start_date			timestamptz,
	company_contact_id		integer,
	company_project_nr		text,
	final_company			text,
	cost_invoices_cache		float,	
	cost_quotes_cache		float,		
	cost_delivery_notes_cache	float,
	cost_bills_cache		float,	
	cost_purchase_orders_cache	float,	
	cost_timesheet_planned_cache	float,	
	cost_timesheet_logged_cache	float,
	cost_expense_planned_cache	float,	
	cost_expense_logged_cache	float,
	reported_hours_cache		float
);

create index im_projects_audit_project_id_idx on im_projects_audit(project_id);





-----------------------------------------------------------
-- Function for accessing the values in an audit_value string
--

-- Extract the value of a specific field from an audit_value
create or replace function im_audit_value (text, text)
returns text as $body$
DECLARE
	p_audit_value	alias for $1;
	p_var_name	alias for $2;

	v_expr		text;
	v_result	text;
BEGIN
	v_expr := p_var_name || '\\t([^\\n]*)';
	select	substring(p_audit_value from v_expr) into v_result from dual;
	IF '' = v_result THEN v_result := null; END IF;

	return v_result;
end; $body$ language 'plpgsql';


-- Extract the value of a specific field from an object at a specific date
create or replace function im_audit_value (integer, text, timestamptz)
returns text as $body$
DECLARE
	p_object_id	alias for $1;
	p_var_name	alias for $2;
	p_audit_date	alias for $3;

	v_audit_value	text;
	v_expr		text;
	v_result	text;
BEGIN
	select	a.audit_value into v_audit_value
	from	im_audits a
	where	a.audit_id = (
			select	max(aa.audit_id)
			from	im_audits aa
			where	aa.audit_object_id = p_object_id and
				aa.audit_date <= p_audit_date
		);

	v_expr := p_var_name || '\\t([^\\n]*)';
	select	substring(v_audit_value from v_expr) into v_result from dual;
	IF '' = v_result THEN v_result := null; END IF;

	return v_result;
end; $body$ language 'plpgsql';


-----------------------------------------------------------
-- Component Plugins
--


SELECT im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Audit Trail Projects',		-- plugin_name - shown in menu
	'intranet-audit',		-- package_name
	'bottom',			-- location
	'/intranet/projects/view',	-- page_url
	null,				-- view_name
	10,				-- sort_order
	'im_audit_component -object_id $project_id'	-- component_tcl
);

SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Audit Trail Projects'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);

SELECT im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Audit Trail Companies',		-- plugin_name - shown in menu
	'intranet-audit',		-- package_name
	'bottom',			-- location
	'/intranet/companies/view',	-- page_url
	null,				-- view_name
	10,				-- sort_order
	'im_audit_component -object_id $company_id'	-- component_tcl
);

SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Audit Trail Companies'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);

SELECT im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Audit Trail Offices',		-- plugin_name - shown in menu
	'intranet-audit',		-- package_name
	'bottom',			-- location
	'/intranet/offices/view',	-- page_url
	null,				-- view_name
	10,				-- sort_order
	'im_audit_component -object_id $office_id'	-- component_tcl
);

SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Audit Trail Offices'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);

SELECT im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Audit Trail Users',		-- plugin_name - shown in menu
	'intranet-audit',		-- package_name
	'bottom',			-- location
	'/intranet/users/view',		-- page_url
	null,				-- view_name
	10,				-- sort_order
	'im_audit_component -object_id $user_id'	-- component_tcl
);

SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Audit Trail Users'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);

SELECT im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Audit Trail Invoices',		-- plugin_name - shown in menu
	'intranet-audit',		-- package_name
	'bottom',			-- location
	'/intranet-invoices/view',	-- page_url
	null,				-- view_name
	10,				-- sort_order
	'im_audit_component -object_id $invoice_id'	-- component_tcl
);

SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Audit Trail Invoices'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);

SELECT im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Audit Trail TS Tasks',		-- plugin_name - shown in menu
	'intranet-audit',		-- package_name
	'bottom',			-- location
	'/intranet-timesheet2-tasks/new',	-- page_url
	null,				-- view_name
	10,				-- sort_order
	'im_audit_component -object_id [im_opt_val task_id]'	-- component_tcl
);

SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Audit Trail TS Tasks'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);

SELECT im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Audit Trail Expense Items',	-- plugin_name - shown in menu
	'intranet-audit',		-- package_name
	'bottom',			-- location
	'/intranet-expenses/new',	-- page_url
	null,				-- view_name
	10,				-- sort_order
	'im_audit_component -object_id $expense_id'	-- component_tcl
);

SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Audit Trail Expense Items'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);


-- SELECT im_component_plugin__new (
-- 	null,				-- plugin_id
-- 	'acs_object',			-- object_type
-- 	now(),				-- creation_date
-- 	null,				-- creation_user
-- 	null,				-- creation_ip
-- 	null,				-- context_id
-- 	'Audit Trail Expense Bundles',	-- plugin_name - shown in menu
-- 	'intranet-audit',		-- package_name
-- 	'bottom',			-- location
-- 	'/intranet-expenses/bundle-new',	-- page_url
-- 	null,				-- view_name
-- 	10,				-- sort_order
-- 	'im_audit_component -object_id $bundle_id'	-- component_tcl
-- );
-- 
-- SELECT acs_permission__grant_permission(
-- 	(select plugin_id from im_component_plugins where plugin_name = 'Audit Trail Expense Bundles'),
-- 	(select group_id from groups where group_name = 'Employees'),
-- 	'read'
-- );


SELECT im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Audit Trail Tickets',		-- plugin_name - shown in menu
	'intranet-audit',		-- package_name
	'bottom',			-- location
	'/intranet-helpdesk/new',	-- page_url
	null,				-- view_name
	10,				-- sort_order
	'im_audit_component -object_id $ticket_id'	-- component_tcl
);

SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Audit Trail Tickets'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);



SELECT im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Audit Trail Conf Items',	-- plugin_name - shown in menu
	'intranet-audit',		-- package_name
	'bottom',			-- location
	'/intranet-confdb/new',	-- page_url
	null,				-- view_name
	10,				-- sort_order
	'im_audit_component -object_id $org_conf_item_id'	-- component_tcl
);

SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Audit Trail Conf Items'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);

SELECT im_component_plugin__new (
	null,				-- plugin_id
	'acs_object',			-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id
	'Audit Trail Absences',		-- plugin_name - shown in menu
	'intranet-audit',		-- package_name
	'bottom',			-- location
	'/intranet-timesheet2/absences/new',	-- page_url
	null,				-- view_name
	10,				-- sort_order
	'im_audit_component -object_id $absence_id'	-- component_tcl
);

SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Audit Trail Absences'),
	(select group_id from groups where group_name = 'Employees'),
	'read'
);




-- Ticket Status Change Matrix
--

SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'24h Status Changes',			-- plugin_name
	'intranet-audit',			-- package_name
	'right',				-- location
	'/intranet-helpdesk/index',		-- page_url
	null,					-- view_name
	180,					-- sort_order
	'im_dashboard_status_matrix -max_category_len 3 -sql "
		select	count(*) as cnt,
			old_status_id,
			new_status_id
		from	(	select	tic.ticket_id,
					pro.project_nr,
					tic.ticket_status_id as new_status_id,
					coalesce(max_audit_a.audit_object_status_id, 0) as old_status_id
				from	im_projects pro,
					im_tickets tic
					LEFT OUTER JOIN (
						select	t.ticket_id,
							max(a.audit_date) as max_audit_date
						from	im_tickets t,
							im_projects p
							LEFT OUTER JOIN im_audits a ON (p.project_id = a.audit_object_id and a.audit_date < now() - ''24 hours''::interval)
						where	t.ticket_id = p.project_id
						group by t.ticket_id
					) max_audit_date ON (tic.ticket_id = max_audit_date.ticket_id)
					LEFT OUTER JOIN im_audits max_audit_a ON (max_audit_a.audit_object_id = tic.ticket_id and max_audit_a.audit_date = max_audit_date.max_audit_date)
				where	tic.ticket_id = pro.project_id
			) t
		group by old_status_id, new_status_id
	" -description "Shows how many tickets have changed their status in the last 24h hours.
	" -status_list [db_list status_list "select distinct ticket_status_id from im_tickets order by ticket_status_id"]',
	'lang::message::lookup "" intranet-reporting-dashboard.Daily_Ticket_Status_Change "Daily Ticket Status Change"'
);


-- Project Status Change Matrix

SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'30 Day Status Changes',		-- plugin_name
	'intranet-audit',			-- package_name
	'right',				-- location
	'/intranet/projects/index',		-- page_url
	null,					-- view_name
	180,					-- sort_order
	'im_dashboard_status_matrix -max_category_len 3 -sql "
		select	count(*) as cnt,
			old_status_id,
			new_status_id
		from	(select	parent.project_status_id as new_status_id,
				max_audit_a.audit_object_status_id as old_status_id
			from	im_projects parent
				LEFT OUTER JOIN (
					select	p.project_id,
						max(a.audit_date) as max_audit_date
					from	im_projects p
						LEFT OUTER JOIN im_audits a ON (p.project_id = a.audit_object_id and a.audit_date < now() - '30 days'::interval)
					where	p.parent_id is null
					group by p.project_id, p.project_status_id
				) max_audit_date ON (parent.project_id = max_audit_date.project_id)
				LEFT OUTER JOIN im_audits max_audit_a ON (max_audit_a.audit_object_id = parent.project_id and max_audit_a.audit_date = max_audit_date.max_audit_date)
			where	parent.parent_id is null
			) t
		group by old_status_id, new_status_id
	" -description "Shows how many projects have changed their status in the last 30 days.
	" -status_list [db_list status_list "select distinct project_status_id from im_projects order by project_status_id"]',
	'lang::message::lookup "" intranet-reporting-dashboard.Monthly_Project_Status_Changes "30 Day Status Changes"'
);

