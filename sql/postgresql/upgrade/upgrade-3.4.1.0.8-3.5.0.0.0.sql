-- upgrade-3.4.1.0.8-3.4.1.0.8.sql

SELECT acs_log__debug('/packages/intranet-helpdesk/sql/postgresql/upgrade/upgrade-3.4.1.0.7-3.4.1.0.8.sql','');


-- Fix the "Summary" tab to show the ticket in read-only mode
update im_menus
set url = '/intranet-helpdesk/new?form_mode=display'
where label = 'helpdesk_summary';


