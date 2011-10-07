-- upgrade-4.0.0.0.1-4.0.0.0.1.sql

SELECT acs_log__debug('/packages/intranet-helpdesk/sql/postgresql/upgrade/upgrade-4.0.0.0.1-4.0.0.0.1.sql','');



-- Create indices on type and status to speedup queries
create index im_ticket_type_id_idx on im_tickets(ticket_type_id);
create index im_ticket_status_id_idx on im_tickets(ticket_status_id);



