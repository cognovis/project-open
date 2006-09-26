



-- Select all subprojects (including the main project)
-- of a "main"-project
select
	p.*
from
	im_projects p
where
	p.project_id in (
                      select    children.project_id
                      from      im_projects parent,
                                im_projects children
                      where
                                children.tree_sortkey
                                        between parent.tree_sortkey
                                        and tree_right(parent.tree_sortkey)
                                and parent.project_id = :project_id
                )




-------------------------------------------------------------
-- Add "Cache" fields to im_projects
--
-- Add fields to store results from adding up costs in
-- the "Finance" view of a project.

alter table im_projects add     cost_quotes_cache		numeric(12,2);
alter table im_projects alter	cost_quotes_cache		set default 0;
alter table im_projects add     cost_invoices_cache		numeric(12,2);
alter table im_projects alter	cost_invoices_cache		set default 0;
alter table im_projects add     cost_timesheet_planned_cache	numeric(12,2);
alter table im_projects alter	cost_timesheet_planned_cache	set default 0;
alter table im_projects add     cost_expense_planned_cache	numeric(12,2);
alter table im_projects alter	cost_expense_planned_cache	set default 0;
alter table im_projects add     cost_purchase_orders_cache	numeric(12,2);
alter table im_projects alter	cost_purchase_orders_cache	set default 0;
alter table im_projects add     cost_bills_cache		numeric(12,2);
alter table im_projects alter	cost_bills_cache		set default 0;
alter table im_projects add     cost_timesheet_logged_cache	numeric(12,2);
alter table im_projects alter	cost_timesheet_logged_cache	set default 0;
alter table im_projects add     cost_expense_logged_cache	numeric(12,2);
alter table im_projects alter	cost_expense_logged_cache	set default 0;
alter table im_projects alter	cost_delivery_notes_cache	numeric(12,2);
alter table im_projects alter	cost_delivery_notes_cache	set default 0;




