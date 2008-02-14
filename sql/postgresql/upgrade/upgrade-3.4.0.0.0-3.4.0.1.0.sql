-- upgrade-3.4.0.0.0-3.4.0.1.0.sql


update im_view_columns
set column_render_tcl = '"<a href=/intranet/projects/view?project_id=$project_id>$project_name</a>"'
where column_id = 3107;
