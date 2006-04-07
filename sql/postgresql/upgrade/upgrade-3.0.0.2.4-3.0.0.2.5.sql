

-- Replace the "start_date" and "end_date" columns
-- in im_projects by timestamptz type
--
BEGIN;
ALTER TABLE im_projects ADD COLUMN end_date_new timestamptz;
UPDATE im_projects SET end_date_new = CAST(end_date AS timestamptz);
ALTER TABLE im_projects DROP COLUMN end_date;
ALTER TABLE im_projects ADD COLUMN end_date timestamptz;
UPDATE im_projects SET end_date = end_date_new;
ALTER TABLE im_projects DROP COLUMN end_date_new;
COMMIT;



BEGIN;
ALTER TABLE im_projects ADD COLUMN start_date_new timestamptz;
UPDATE im_projects SET start_date_new = CAST(start_date AS timestamptz);
ALTER TABLE im_projects DROP COLUMN start_date;
ALTER TABLE im_projects ADD COLUMN start_date timestamptz;
UPDATE im_projects SET start_date = start_date_new;
ALTER TABLE im_projects DROP COLUMN start_date_new;
COMMIT;



-- use "formatted" start date in project views
--
delete from im_view_columns where column_id=2215;
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2215,22,NULL,'Start Date',
'$start_date_formatted','','',15,'');

delete from im_view_columns where column_id=2015;
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2015,20,NULL,'Start Date',
'$start_date_formatted','','',8,'');


-- use "formatted" end date in project views
--
delete from im_view_columns where column_id=2217;
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2217,22,NULL,'Delivery Date',
'$end_date_formatted','','',16,'');

delete from im_view_columns where column_id=2017;
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2017,20,NULL,'Delivery Date',
'$end_date_formatted','','',9,'');
