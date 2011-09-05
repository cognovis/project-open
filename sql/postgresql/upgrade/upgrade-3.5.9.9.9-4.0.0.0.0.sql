-- upgrade-3.5.9.9.9-4.0.0.0.0.sql

SELECT acs_log__debug('/packages/intranet-translation/sql/postgresql/upgrade/upgrade-3.5.9.9.9-4.0.0.0.0.sql','');

-- Delete previous columns.
delete from im_view_columns where view_id = 90;



-- Allow translation tasks to be checked/unchecked all together
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl, extra_select, extra_where, sort_order, visible_for)
values (9000,90,NULL,'<input type=checkbox name=_dummy onclick="acs_ListCheckAll(''task'',this.checked)">','$del_checkbox','','', 0,'expr $project_write');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9010,90,NULL,'Task Name','$task_name_splitted','','',100,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9012,90,NULL,'Target Lang','$target_language','','',120,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9014,90,NULL,'XTr','$match_x','','',140,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9016,90,NULL,'Rep','$match_rep','','',150,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9018,90,NULL,'100 %','$match100','','',180,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9020,90,NULL,'95 %','$match95','','',200,'im_permission $user_id view_trans_task_matrix');
-- 9021 blocked, this was the old checkbox column
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9022,90,NULL,'85 %','$match85','','',220,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9024,90,NULL,'75 %','$match75','','',240,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9026,90,NULL,'50 %','$match50','','',260,'im_permission $user_id view_trans_task_matrix');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9028,90,NULL,'0 %','$match0','','',280,'im_permission $user_id view_trans_task_matrix');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9040,90,NULL,'Units','$task_units $uom_name','','',400,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9042,90,NULL,'Bill. Units','$billable_items_input','','',420,'expr $project_write');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9044,90,NULL,'Bill. Units Interco','$billable_items_input_interco','','',440,'expr $project_write && $interco_p');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9050,90,NULL,'Quoted Price','$quoted_price','','',500,'im_permission $user_id view_finance');

-- Show cost and margin only to WhP
-- insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
-- values (9052,90,NULL,'Ordered Cost','$po_cost','','',520,'im_permission $user_id view_finance');
-- insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
-- values (9054,90,NULL,'Gross Margin','$gross_margin','','',540,'im_permission $user_id view_finance');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9060,90,NULL,'End Date','$end_date_formatted','','',600,'expr !$project_write');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9062,90,NULL,'End Date','$end_date_input','','',620,'expr $project_write');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9064,90,NULL,'Task Type','$type_select','','',640,'expr $project_write');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9066,90,NULL,'Task Status','$status_select','','',660,'expr $project_write');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9080,90,NULL,'Assigned','$assignments','','',800,'expr $project_write');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9082,90,NULL,'Message','$message','','',820,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9084,90,NULL,'[im_gif save "Download files"]','$download_link','','',840,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,extra_select, extra_where, sort_order, visible_for)
values (9086,90,NULL,'[im_gif open "Upload files"]','$upload_link','','',860,'');


-- Add DynFields with default values for the new surcharge/discount/pm_fee fields of FinDocs

create or replace function inline_0 ()
returns integer as '
declare
        v_count         integer;
begin

        select count(*) into v_count from information_schema.columns where 
              table_name = ''im_companies'' 
              and column_name = ''default_pm_fee_perc'';
        IF v_count > 0 THEN return 1; END IF;
	alter table im_companies add default_pm_fee_perc numeric(12,2);
        RETURN 0;

end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
        v_count         integer;
begin

        select count(*) into v_count from information_schema.columns where
              table_name = ''im_companies''
              and column_name = ''default_surcharge_perc'';
        IF v_count > 0 THEN return 1; END IF;
        alter table im_companies add default_surcharge_perc numeric(12,2);
        RETURN 0;

end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

create or replace function inline_0 ()
returns integer as '
declare
        v_count         integer;
begin

        select count(*) into v_count from information_schema.columns where
              table_name = ''im_companies''
              and column_name = ''default_discount_perc'';
        IF v_count > 0 THEN return 1; END IF;
        alter table im_companies add default_discount_perc numeric(12,2);
        RETURN 0;

end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


SELECT im_dynfield_attribute_new ('im_company', 'default_pm_fee_perc', 'Default PM Fee Percentage', 'numeric', 'float', 'f');
SELECT im_dynfield_attribute_new ('im_company', 'default_surcharge_perc', 'Default Surcharge Percentage', 'numeric', 'float', 'f');
SELECT im_dynfield_attribute_new ('im_company', 'default_discount_perc', 'Default Discount Percentage', 'numeric', 'float', 'f');

SELECT im_dynfield_attribute_new ('im_company', 'default_tax', 'Default TAX', 'numeric', 'float', 'f');


