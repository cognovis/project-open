-- upgrade-3.4.0.8.0-3.4.0.8.1.sql

SELECT acs_log__debug('/packages/intranet-hr/sql/postgresql/upgrade/upgrade-3.4.0.8.0-3.4.0.8.1.sql','');



create or replace function inline_0 ()
returns integer as '
declare
        v_count                 integer;
begin
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = ''im_employees'' and lower(column_name) = ''vacation_balance'';
        if v_count > 0 then return 0; end if;

	alter table im_employees add column vacation_days_per_year numeric(12,2);
	alter table im_employees add column vacation_balance numeric(12,2);

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



delete from im_view_columns where column_id in (5630, 5632);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5630,56,'Vacation Days per Year','$vacation_days_per_year',30);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5632,56,'Vacation Balance From Last Year','$vacation_balance',32);



