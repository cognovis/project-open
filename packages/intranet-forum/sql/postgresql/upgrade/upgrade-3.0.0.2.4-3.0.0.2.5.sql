-- upgrade-3.0.0.2.4-3.0.0.2.5.sql

SELECT acs_log__debug('/packages/intranet-forum/sql/postgresql/upgrade/upgrade-3.0.0.2.4-3.0.0.2.5.sql','');


-- Add a new "view_topics_all" privilege
-- to allow SenMan etc to see everything.

select acs_privilege__create_privilege('view_topics_all','View all topics','');
select acs_privilege__add_child('admin', 'view_topics_all');

select im_priv_create('view_topics_all',        'Employees');
select im_priv_create('view_topics_all',        'P/O Admins');
select im_priv_create('view_topics_all',        'Project Managers');
select im_priv_create('view_topics_all',        'Senior Managers');


delete from im_view_columns where column_id=4006;
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (4006,40,NULL,'Due',
'[if {$overdue > 0} {
        set t "<font color=red>$due_date</font>"
} else {
        set t "$due_date"
}]','','',8,'');


delete from im_view_columns where column_id=4106;
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (4106,41,NULL,'Due',
'[if {$overdue > 0} {
        set t "<font color=red>$due_date</font>"
} else {
        set t "$due_date"
}]','','',8,'');


delete from im_view_columns where column_id=4106;
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (4106,41,NULL,'Due',
'[if {$overdue > 0} {
        set t "<font color=red>$due_date</font>"
} else {
        set t "$due_date"
}]','','',8,'');


delete from im_view_columns where column_id=4206;
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (4206,42,NULL,'Due',
'[if {$overdue > 0} {
        set t "<font color=red>$due_date</font>"
} else {
        set t "$due_date"
}]','','',8,'');


delete from im_view_columns where column_id=4406;
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (4406,44,NULL,'Due',
'[if {$overdue > 0} {
        set t "<font color=red>$due_date</font>"
} else {
        set t "$due_date"
}]','','',8,'');


delete from im_view_columns where column_id=4506;
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (4506,45,NULL,'Due',
'[if {$overdue > 0} {
        set t "<font color=red>$due_date</font>"
} else {
        set t "$due_date"
}]','','',8,'');


delete from im_view_columns where column_id=4606;
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (4606,46,NULL,'Due',
'[if {$overdue > 0} {
        set t "<font color=red>$due_date</font>"
} else {
        set t "$due_date"
}]','','',8,'');

