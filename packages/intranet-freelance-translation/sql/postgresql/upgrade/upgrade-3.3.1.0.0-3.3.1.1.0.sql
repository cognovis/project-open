-- upgrade-3.3.1.0.0-3.3.1.1.0.sql

SELECT acs_log__debug('/packages/intranet-freelance-translation/sql/postgresql/upgrade/upgrade-3.3.1.0.0-3.3.1.1.0.sql','');


--------------------------------------------------------------
-- TransFreelancersListPage
--
delete from im_view_columns where view_id = 53;
delete from im_views where view_id = 53;
insert into im_views (view_id, view_name, visible_for) values (53, 'trans_freelancers_list', '');

insert into im_view_columns (column_id, view_id, group_id, column_name, 
column_render_tcl, extra_select, extra_from, extra_where, sort_order, 
visible_for) values (5300,53,NULL,'Name',
'"<a href=/intranet/users/view?user_id=$user_id>$name</a>"','','','',0,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, 
column_render_tcl, extra_select, extra_where, sort_order, visible_for) values (
5301,53,NULL,'Email','"<a href=mailto:$email>$email</a>"','','',2,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, 
column_render_tcl, extra_select, extra_where, sort_order, visible_for) values (
5304,53,NULL,'Work Phone',
'$work_phone','','',4,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, 
column_render_tcl, extra_select, extra_where, sort_order, visible_for) values (
5305,53,NULL,'Cell Phone','$cell_phone','','',5,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, 
column_render_tcl, extra_select, extra_where, sort_order, visible_for) values (
5306,53,NULL,'Home Phone','$home_phone','','',6,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, 
column_render_tcl, extra_select, extra_where, sort_order, visible_for, order_by_clause) 
values (5308,53,NULL,'Recr Status','$rec_status',
'im_category_from_id(rec_status_id) as rec_status','',8,'','order by rec_status');

insert into im_view_columns (column_id, view_id, group_id, column_name, 
column_render_tcl, extra_select, extra_where, sort_order, visible_for, order_by_clause) 
values (5310,53,NULL,'Recr Test','$rec_test_result',
'im_category_from_id(rec_test_result_id) as rec_test_result','',10,'',
'order by rec_test_result_id');

insert into im_view_columns (column_id, view_id, group_id, column_name, 
column_render_tcl, extra_select, extra_where, sort_order, visible_for) values (
5320,53,NULL,'S-Word','$s_word_price','','',20,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, 
column_render_tcl, extra_select, extra_where, sort_order, visible_for) values (
5322,53,NULL,'Hour','$hour_price','','',22,'');


