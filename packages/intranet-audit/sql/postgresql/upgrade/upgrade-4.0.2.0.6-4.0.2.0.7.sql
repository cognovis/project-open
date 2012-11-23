-- upgrade-4.0.2.0.6-4.0.2.0.7.sql

SELECT acs_log__debug('/packages/intranet-audit/sql/postgresql/upgrade/upgrade-4.0.2.0.6-4.0.2.0.7.sql','');



create or replace function inline_0 ()
returns integer as $body$
DECLARE
	v_count		integer;
BEGIN
	select count(*) into v_count from user_tab_columns
	where  lower(table_name) = 'im_projects_audit' and lower(column_name) = 'audit_id';
	IF v_count > 0 THEN return 1; END IF;

	alter table im_projects_audit
	add column audit_id integer;

	return 0;
end; $body$ language 'plpgsql';
select inline_0();
drop function inline_0();



-- Drop the NOT NULL constraint
alter table im_audits alter column audit_diff DROP not null;





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
						LEFT OUTER JOIN im_audits a ON (p.project_id = a.audit_object_id and a.audit_date < now() - ''30 days''::interval)
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
