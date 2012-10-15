-- upgrade-4.0.3.0.2-4.0.3.0.3.sql

SELECT acs_log__debug('/packages/intranet-riskmanagement/sql/postgresql/upgrade/upgrade-4.0.3.0.2-4.0.3.0.3.sql','');


delete from im_view_columns where column_id = 21010;
insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(21010, 210, 10, 'Name', '"<a href=/intranet-riskmanagement/new?form_mode=display&risk_id=$risk_id>$risk_name</a>"');
