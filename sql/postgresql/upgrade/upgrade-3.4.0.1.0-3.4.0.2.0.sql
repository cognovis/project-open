-- upgrade-3.4.0.1.0-3.4.0.2.0.sql


SELECT im_category_new(15000, 'Active', 'Intranet Report Status');
SELECT im_category_new(15002, 'Deleted', 'Intranet Report Status');

SELECT im_category_new(15100, 'Simple SQL Report', 'Intranet Report Type');
SELECT im_category_new(15110, 'Indicator', 'Intranet Report Type');



create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select	count(*) into v_count from user_tab_columns
	where	table_name = ''IM_REPORTS'' and column_name = ''REPORT_CODE'';
	if v_count > 0 then return 0; end if;

	alter table im_reports
	add report_code varchar(100);

    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0();


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select	count(*) into v_count from user_tab_columns
	where	table_name = ''IM_REPORTS'' and column_name = ''REPORT_DESCRIPTION'';
	if v_count > 0 then return 0; end if;

	alter table im_reports
	add report_description text;

    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0();

create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select	count(*) into v_count from user_tab_columns
	where	table_name = ''IM_REPORTS'' and column_name = ''REPORT_SORT_ORDER'';
	if v_count > 0 then return 0; end if;

	alter table im_reports
	add report_sort_order integer;

    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0();

