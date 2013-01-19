-- 
-- 
-- 
-- @author Malte Sussdorff (malte.sussdorff@cognovis.de)
-- @creation-date 2012-12-15
-- @cvs-id $Id$
--

SELECT acs_log__debug('/packages/intranet-timesheet2-tasks/sql/postgresql/upgrade/upgrade-4.0.3.2.1-4.0.3.2.2.sql','');

-- make sure that project status is set to closed
update im_projects set project_status_id = 81 where project_id in (select task_id from im_timesheet_tasks where task_status_id in (select * from im_sub_categories(9601)) limit 500) and project_status_id != 81;
