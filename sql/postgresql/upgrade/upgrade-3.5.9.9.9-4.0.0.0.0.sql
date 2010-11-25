-- upgrade-3.5.9.9.9-4.0.0.0.0.sql

SELECT acs_log__debug('/packages/intranet-invoices/sql/postgresql/upgrade/upgrade-3.5.9.9.9-4.0.0.0.0.sql','');

-- Move the "Sel" column to the left
update im_view_columns set sort_order = 0 where column_id = 3115;

