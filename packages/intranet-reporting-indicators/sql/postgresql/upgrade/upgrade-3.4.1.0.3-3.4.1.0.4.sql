-- upgrade-3.4.1.0.3-3.4.1.0.4.sql

SELECT acs_log__debug('/packages/intranet-reporting-indicators/sql/postgresql/upgrade/upgrade-3.4.1.0.3-3.4.1.0.4.sql','');



create or replace function inline_0 ()
returns integer as $body$
DECLARE
	v_id			integer;
	v_count			integer;
BEGIN
	SELECT	count(*) INTO v_count
	FROM	im_reports where report_code = 'invoicable_hours';
	IF v_count > 0 THEN return 1; END IF;

	v_id := im_indicator__new(
		null, 'im_indicator', now(), 0, '', null,
		'Invoicable Hours',
		'invoicable_hours',
		15110,
		15000,
		'
select
	sum(h.hours)
from
	im_hours h,
	im_projects parent,
	im_projects child
	LEFT OUTER JOIN im_timesheet_tasks t ON (child.project_id = t.task_id)
where
	h.project_id = child.project_id and
	parent.parent_id is null and
	child.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey) and
	h.invoice_id is null and
	parent.project_status_id not in (82) and
	child.project_status_id not in (82)
		',
		0,
		10000,
		5
	);

	update im_indicators set
		indicator_section_id = 15215
	where indicator_id = v_id;

	update im_reports set
		report_description = '
Returns the number of hours that have been reported but not yet invoiced.
The report excludes projects in status "deleted", but otherwise counts all
hours that have not yet been assigned to any invoice.
'
	where report_id = v_id;

        return 0;
end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();





