-- upgrade-3.4.0.7.4-3.4.0.7.5.sql

SELECT acs_log__debug('/packages/intranet-helpdesk/sql/postgresql/upgrade/upgrade-3.4.0.7.4-3.4.0.7.5.sql','');

SELECT im_category_new(30122, 'Nagios Alert', 'Intranet Ticket Type');
SELECT im_category_hierarchy_new(30120, 30150);

delete from im_view_columns where column_id = 270220;
insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(270220,270,22,'Conf Item','"<A href=/intranet-confdb/new?form_mode=display&conf_item_id=$conf_item_id>$conf_item_name</a>"');

