-- upgrade-3.2.1.0.0-3.2.2.0.0.sql

SELECT acs_log__debug('/packages/intranet-dw-light/sql/postgresql/upgrade/upgrade-3.2.1.0.0-3.2.2.0.0.sql','');

-- -------------------------------------------------------------------
-- Cost Centers


create or replace function inline_1 ()
returns integer as '
declare
	v_count			integer;
begin
	select count(*) into v_count from im_views
	where view_id = 34;
	if v_count = 0 then return 0; end if;

	delete from im_view_columns where column_id = 3402;

	insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
	extra_select, extra_where, sort_order, visible_for) values (
	3402,34,NULL,''CostCenter'',''$cost_center_code'','''','''',2,'''');

	return 0;
end;' language 'plpgsql';
select inline_1 ();
drop function inline_1 ();








