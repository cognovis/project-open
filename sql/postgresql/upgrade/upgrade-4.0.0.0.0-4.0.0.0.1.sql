-- upgrade-4.0.0.0.0-4.0.0.0.1.sql

SELECT acs_log__debug('/packages/intranet-helpdesk/sql/postgresql/upgrade/upgrade-4.0.0.0.0-4.0.0.0.1.sql','');

SELECT im_category_new(30560, 'Resolved', 'Intranet Ticket Action');


