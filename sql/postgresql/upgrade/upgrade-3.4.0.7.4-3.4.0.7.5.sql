-- upgrade-3.4.0.7.4-3.4.0.7.5.sql

SELECT acs_log__debug('/packages/intranet-helpdesk/sql/postgresql/upgrade/upgrade-3.4.0.7.4-3.4.0.7.5.sql','');

SELECT im_category_new(30122, 'Nagios Alert', 'Intranet Ticket Type');
SELECT im_category_hierarchy_new(30120, 30150);

