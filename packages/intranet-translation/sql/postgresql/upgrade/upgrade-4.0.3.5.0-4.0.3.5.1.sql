-- upgrade-4.0.3.5.0-4.0.3.5.1.sql

SELECT acs_log__debug('/packages/intranet-translation/sql/postgresql/upgrade/upgrade-4.0.3.5.0-4.0.3.5.1.sql','');


create or replace function inline_0 ()
returns integer as $body$
declare
	v_count	integer;
begin
	-- perfect matches
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = 'im_trans_tasks' and lower(column_name) = 'match_perf';
	IF v_count = 0 THEN
		alter table im_trans_tasks add column match_perf numeric(12,0) default 0;
	END IF;

	-- crossfilerepeated
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = 'im_trans_tasks' and lower(column_name) = 'match_cfr';
	IF v_count = 0 THEN
		alter table im_trans_tasks add column match_cfr numeric(12,0) default 0;
	END IF;

	-- fuzzy 95
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = 'im_trans_tasks' and lower(column_name) = 'match_f95';
	IF v_count = 0 THEN
		alter table im_trans_tasks add column match_f95 numeric(12,0) default 0;
	END IF;

	-- fuzzy 85
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = 'im_trans_tasks' and lower(column_name) = 'match_f85';
	IF v_count = 0 THEN
		alter table im_trans_tasks add column match_f85 numeric(12,0) default 0;
	END IF;

	-- fuzzy 75
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = 'im_trans_tasks' and lower(column_name) = 'match_f75';
	IF v_count = 0 THEN
		alter table im_trans_tasks add column match_f75 numeric(12,0) default 0;
	END IF;

	-- fuzzy 50
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = 'im_trans_tasks' and lower(column_name) = 'match_f50';
	IF v_count = 0 THEN
		alter table im_trans_tasks add column match_f50 numeric(12,0) default 0;
	END IF;

	return 0;
end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




create or replace function inline_0 ()
returns integer as $body$
declare
	v_count	integer;
begin
	-- perfect matches
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = 'im_trans_trados_matrix' and lower(column_name) = 'match_perf';
	IF v_count = 0 THEN
		alter table im_trans_trados_matrix add column match_perf numeric(12,4) default 0;
	END IF;

	-- crossfilerepeated
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = 'im_trans_trados_matrix' and lower(column_name) = 'match_cfr';
	IF v_count = 0 THEN
		alter table im_trans_trados_matrix add column match_cfr numeric(12,4) default 1;
	END IF;

	-- fuzzy 95
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = 'im_trans_trados_matrix' and lower(column_name) = 'match_f95';
	IF v_count = 0 THEN
		alter table im_trans_trados_matrix add column match_f95 numeric(12,4) default 1;
	END IF;

	-- fuzzy 85
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = 'im_trans_trados_matrix' and lower(column_name) = 'match_f85';
	IF v_count = 0 THEN
		alter table im_trans_trados_matrix add column match_f85 numeric(12,4) default 1;
	END IF;

	-- fuzzy 75
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = 'im_trans_trados_matrix' and lower(column_name) = 'match_f75';
	IF v_count = 0 THEN
		alter table im_trans_trados_matrix add column match_f75 numeric(12,4) default 1;
	END IF;

	-- fuzzy 50
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = 'im_trans_trados_matrix' and lower(column_name) = 'match_f50';
	IF v_count = 0 THEN
		alter table im_trans_trados_matrix add column match_f50 numeric(12,4) default 1;
	END IF;

	return 0;
end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();






-- 9068-9079 reserved

delete from im_view_columns where column_id in (9068, 9069, 9070, 9071, 9072, 9073);

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9068,90,NULL,'Perf','$match_perf','','',290,'im_permission $user_id view_trans_task_matrix');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9069,90,NULL,'Cfr','$match_cfr','','',291,'im_permission $user_id view_trans_task_matrix');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9070,90,NULL,'f95 %','$match_f95','','',292,'im_permission $user_id view_trans_task_matrix');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9071,90,NULL,'f85 %','$match_f85','','',293,'im_permission $user_id view_trans_task_matrix');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9072,90,NULL,'f75 %','$match_f75','','',294,'im_permission $user_id view_trans_task_matrix');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9073,90,NULL,'f50 %','$match_f50','','',295,'im_permission $user_id view_trans_task_matrix');

