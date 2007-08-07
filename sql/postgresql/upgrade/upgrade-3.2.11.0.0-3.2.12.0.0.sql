-- upgrade-3.2.11.0.0-3.2.12.0.0.sql

update im_view_columns
set column_render_tcl = '"<a href=/intranet-cost/cost-centers/new?[export_url_vars cost_center_id return_url]>$cost_center_name</a>"'
where column_id = 91006;

