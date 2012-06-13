--  upgrade-4.0.2.0.6-4.0.2.0.7.sql

SELECT acs_log__debug('/packages/intranet-helpdesk/sql/postgresql/upgrade/upgrade-4.0.2.0.6-4.0.2.0.7.sql','');

SELECT im_category_new(30545, 'Change Prio', 'Intranet Ticket Action');
