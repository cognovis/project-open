-- upgrade-4.0.0.0.0-4.0.0.0.1.sql

SELECT acs_log__debug('/packages/intranet-helpdesk/sql/postgresql/upgrade/upgrade-4.0.0.0.0-4.0.0.0.1.sql','');

SELECT im_category_new(30560, 'Resolved', 'Intranet Ticket Action');


-- Add new actions
SELECT im_category_new(30540, 'Associate', 'Intranet Ticket Action');
SELECT im_category_new(30550, 'Escalate', 'Intranet Ticket Action');
SELECT im_category_new(30552, 'Close Escalated Tickets', 'Intranet Ticket Action');
