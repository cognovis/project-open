-- upgrade-3.4.1.0.6-3.4.1.0.8.sql

SELECT acs_log__debug('/packages/intranet-helpdesk/sql/postgresql/upgrade/upgrade-3.4.1.0.6-3.4.1.0.8.sql','');


SELECT im_category_new(30540, 'Associate', 'Intranet Ticket Action');
