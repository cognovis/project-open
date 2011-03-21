-- upgrade-3.3.1.1.0-3.3.1.1.0.sql

SELECT acs_log__debug('/packages/intranet-trans-invoices/sql/postgresql/upgrade/upgrade-3.3.1.1.0-3.3.1.2.0.sql','');


update im_view_columns 
set column_render_tcl = '"<input type=checkbox name=select_project value=$project_id checked>"'
where column_id = 3115;
