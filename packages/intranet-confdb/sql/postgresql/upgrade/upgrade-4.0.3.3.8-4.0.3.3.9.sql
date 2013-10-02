-- upgrade-4.0.3.3.8-4.0.3.3.9.sql

SELECT acs_log__debug('/packages/intranet-confdb/sql/postgresql/upgrade/upgrade-4.0.3.3.8-4.0.3.3.9.sql','');

create or replace function inline_0 ()
returns integer as $body$
declare
        v_count         integer;
begin
        -- Sanity check if column exists
        select count(*) into v_count from im_views where view_id  = 941;
        IF v_count > 0 THEN return 1; END IF;

	insert into im_views (view_id, view_name, visible_for) values (941, 'im_conf_item_list_short', 'view_conf_items');


	insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
	extra_select, extra_where, sort_order, visible_for) values (94101,941,NULL,
	'"[im_gif del "Delete"]"', '"<input type=checkbox name=conf_item_id.$conf_item_id>"', '', '', 1, '');

	insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
	extra_select, extra_where, sort_order, visible_for) values (94105, 941, NULL, '"Name"',
	'"<nobr>$indent_short_html$gif_html<a href=$object_url>$conf_item_name</a></nobr>"','','',5,'');

	insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
	extra_select, extra_where, sort_order, visible_for) values (94110, 941, NULL, '"Type"',
	'"<nobr>$conf_item_type</nobr>"','','',10,'');

        return 0;

end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

