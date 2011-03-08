delete from im_view_columns where view_id = 921;
delete from im_views where view_id = 921;

insert into im_views (view_id, view_name, visible_for, view_type_id)
values (921, 'portfolio_department_planner_list_ajax', 'view_users', 1415);


insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for,ajax_configuration) values (92015,921,NULL,'Priority','"$project_priority"','','',5,'','hidden project_priority "$project_priority"');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for,ajax_configuration) values (92016,921,NULL,'Project ID','"$project_id"','','',0,'','hidden project_id "$project_id"');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for,ajax_configuration) values (92025,921,NULL,'Project',
'"<nobr>$indent_html$gif_html<a href=[export_vars -base $project_base_url {project_id}]>$project_name</a></nobr>"','','',15,'','link Projekt "<nobr>$indent_html$gif_html<a href=[export_vars -base $project_base_url {project_id}]>$project_name</a></nobr>" 1 1');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for,ajax_configuration) values (92026,921,NULL,'Operational Priority',
'"[im_category_from_id $project_priority_op_id]"','','',6,'','	dropdown project_priority_op_id { [im_department_planner_priority_list] } 1 1
');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for,ajax_configuration) values (92027,921,NULL,'Strategic Priority',
'"[im_category_from_id $project_priority_st_id]"','','',10,'','	dropdown project_priority_st_id { [im_department_planner_priority_list] } 1 1
');

