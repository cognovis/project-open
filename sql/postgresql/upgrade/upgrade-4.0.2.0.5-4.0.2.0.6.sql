-- upgrade-4.0.2.0.5-4.0.2.0.6.sql

SELECT acs_log__debug('/packages/intranet-sencha-ticket-tracker/sql/postgresql/upgrade/upgrade-4.0.2.0.5-4.0.2.0.6.sql','');


alter table im_tickets
add ticket_action_count numeric(12,2) default 1.0;
