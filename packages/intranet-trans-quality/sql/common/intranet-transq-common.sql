-- /packages/intranet-trans-quality/sql/common/intranet-transq-create.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com
-- @author juanjoruizx@yahoo.es


-- --------------------------------------------------------------------
-- Translation Quality Type Category
--

delete from im_categories where category_id >= 7000 and category_id < 7100;

INSERT INTO im_categories (category_id,category,category_type) VALUES 
(7002,'Mistranslation','Intranet Translation Quality Type');
INSERT INTO im_categories (category_id,category,category_type) VALUES 
(7004,'Accuracy','Intranet Translation Quality Type');
INSERT INTO im_categories (category_id,category,category_type) VALUES 
(7006,'Terminology','Intranet Translation Quality Type');
INSERT INTO im_categories (category_id,category,category_type) VALUES 
(7008,'Language','Intranet Translation Quality Type');
INSERT INTO im_categories (category_id,category,category_type) VALUES 
(7010,'Style','Intranet Translation Quality Type');
INSERT INTO im_categories (category_id,category,category_type) VALUES 
(7012,'Country','Intranet Translation Quality Type');
INSERT INTO im_categories (category_id,category,category_type) VALUES 
(7014,'Consistency','Intranet Translation Quality Type');



-- --------------------------------------------------------------------
-- views for transq: 250-259


delete from im_view_columns where column_id > 25000 and column_id < 25099;
delete from im_view_columns where column_id > 25100 and column_id < 25199;
delete from im_views where view_id >= 250 and view_id <= 259;

insert into im_views (view_id, view_name, visible_for)
values (250, 'transq_task_list', '');

insert into im_views (view_id, view_name, visible_for)
values (251, 'transq_task_select', '');



-- --------------------------------------------------------------------
-- TransQ Task List Page
--
delete from im_view_columns where column_id > 25000 and column_id < 25099;
--
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (25001,250,'Task Name',
'$task_name',1);

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (25003,250,'Source','$source_language',3);

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (25005,250,'Target', '$target_language',5);

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (25007,250,'Units','$task_units',7);

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (25011,250,'Quality', '$expected_quality',11);

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (25013,250,'Report', 
'"<a href=/intranet-trans-quality/new?task_id=$task_id>$total_errors / $allowed_errors</a>"'
,13);




-- --------------------------------------------------------------------
-- TransQ Task Select Page
-- Allows to select a task for adding a Q-Report
--
delete from im_view_columns where column_id > 25100 and column_id < 25199;
--
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (25101,251,'Task Name',
'$task_name',1);

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (25103,251,'Source','$source_language',3);

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (25105,251,'Target', '$target_language',5);

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (25107,251,'Units','$task_units',7);

-- insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
-- sort_order) values (25111,251,'Quality', '$expected_quality',11);

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (25113,251,'Report', 
'"<a href=/intranet-trans-quality/new?task_id=$task_id>Select</a>"'
,13);








