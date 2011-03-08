-- upgrade-3.4.1.0.5-3.4.1.0.6.sql

SELECT acs_log__debug('/packages/intranet-helpdesk/sql/postgresql/upgrade/upgrade-3.4.1.0.5-3.4.1.0.6.sql','');


-- Add new ticket status for Outlook integration

SELECT im_category_new(30026, 'Waiting for Other', 'Intranet Ticket Status');
SELECT im_category_hierarchy_new(30026, 30000);

