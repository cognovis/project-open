-- upgrade-3.4.1.0.8-3.5.0.0.0.sql

SELECT acs_log__debug('/packages/intranet-helpdesk/sql/postgresql/upgrade/upgrade-3.4.1.0.8-3.5.0.0.0.sql','');


-- Fix the "Summary" tab to show the ticket in read-only mode
update im_menus
set url = '/intranet-helpdesk/new?form_mode=display'
where label = 'helpdesk_summary';

-- Rename 'Helpdesk' into "Tickets"
update im_menus
set name = 'Tickets'
where label = 'helpdesk';

-- Move the Checkboxes to the left
update im_view_columns
set sort_order = -1
where column_id = 27099;

