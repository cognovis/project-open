
-- Add a "CostCenter" column to the main Inovice list
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (3002,30,NULL,'CC',
'$cost_center_code','','',2,'');


-- Dont show a link to the invoice if the user cant read it.
-- delete from im_view_columns where column_id = 3001;
-- insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
-- extra_select, extra_where, sort_order, visible_for) values (3001,30,NULL,'Document #',
-- '$invoice_nr_link','','',1,'');


-- Dont show status_select for an invoice if the user cant read it.
delete from im_view_columns where column_id = 3017;
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (3017,30,NULL,'Status',
'$status_select','','',17,'');
