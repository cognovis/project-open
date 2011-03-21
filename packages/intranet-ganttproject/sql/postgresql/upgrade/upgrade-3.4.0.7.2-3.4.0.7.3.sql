-- upgrade-3.4.0.7.2-3.4.0.7.3.sql

SELECT acs_log__debug('/packages/intranet-ganttproject/sql/postgresql/upgrade/upgrade-3.4.0.7.2-3.4.0.7.3.sql','');



----------------------------------------------------------------
-- Privilege to download the GanttProject file of a project
----------------------------------------------------------------

-- Should Freelancers/Customers see the project Gantt details?
select acs_privilege__create_privilege('view_gantt_proj_detail',
        'View Gantt Project Details', 'View Gantt Project Details');
select acs_privilege__add_child('admin','view_gantt_proj_detail');

select im_priv_create('view_gantt_proj_detail', 'Employees');


