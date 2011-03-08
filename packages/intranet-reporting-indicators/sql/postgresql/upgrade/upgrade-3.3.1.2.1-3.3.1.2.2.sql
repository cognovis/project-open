-- upgrade-3.3.1.2.1-3.3.1.2.2.sql

SELECT acs_log__debug('/packages/intranet-reporting-indicators/sql/postgresql/upgrade/upgrade-3.3.1.2.1-3.3.1.2.2.sql','');

\i upgrade-3.0.0.0.first.sql

create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from user_tab_columns
	where table_name = ''IM_INDICATORS'' and column_name = ''INDICATOR_OBJECT_TYPE'';
	IF v_count > 0 THEN return 0; END IF;

	alter table im_indicators
	add indicator_object_type varchar(100)
        constraint im_indicator_otype_fk references acs_object_types;

	alter table im_indicators add indicator_low_warn	double precision;
	alter table im_indicators add indicator_low_critical	double precision;
	alter table im_indicators add indicator_high_warn	double precision;
	alter table im_indicators add indicator_high_critical	double precision;

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from user_tab_columns
	where table_name = ''IM_INDICATOR_RESULTS'' and column_name = ''RESULT_OBJECT_ID'';
	IF v_count > 0 THEN return 0; END IF;

	alter table im_indicator_results
	add result_object_id integer
	constraint im_indicator_result_object_fk references acs_objects;

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




