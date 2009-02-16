-- upgrade-3.2.9.0.0-3.3.0.0.0.sql

SELECT acs_log__debug('/packages/intranet-timesheet2-tasks/sql/postgresql/upgrade/upgrade-3.2.9.0.0-3.3.0.0.0.sql','');


create or replace function inline_0 ()
returns integer as '
declare
        v_count         integer;
begin
        select count(*) into v_count from pg_views
        where lower(viewname) = ''im_timesheet_tasks_view'';
        IF v_count = 0 THEN return 0; END IF;

	drop view im_timesheet_tasks_view;

        return v_count;
end;' language 'plpgsql';
SELECT inline_0();
DROP FUNCTION inline_0();


create or replace view im_timesheet_tasks_view as
select  t.*,
        p.parent_id as project_id,
        p.project_name as task_name,
        p.project_nr as task_nr,
        p.percent_completed,
        p.project_type_id as task_type_id,
        p.project_status_id as task_status_id,
        p.start_date,
        p.end_date,
	p.reported_hours_cache,
	p.reported_hours_cache as reported_units_cache
from
        im_projects p,
        im_timesheet_tasks t
where
        t.task_id = p.project_id
;
