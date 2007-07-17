-- upgrade-3.2.11.0.0-3.2.12.0.0.sql

-- Category for canned note
alter table im_invoices add canned_note_id integer;

