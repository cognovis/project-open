-- upgrade-3.2.6.0.0-3.2.7.0.0.sql

SELECT acs_log__debug('/packages/intranet-dynfield/sql/postgresql/upgrade/upgrade-3.2.6.0.0-3.2.7.0.0.sql','');


create or replace function inline_0 ()
returns integer as '
declare
	v_count		 integer;
begin
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = ''im_dynfield_attributes'' and lower(column_name) = ''include_in_search_p'';
	IF 0 != v_count THEN return 0; END IF;

	alter table im_dynfield_attributes add include_in_search_p char(1);
	alter table im_dynfield_attributes alter column include_in_search_p set default ''f'';
	update im_dynfield_attributes set include_in_search_p = ''f'';
	alter table im_dynfield_attributes 
		add constraint im_dynfield_attributes_search_ch 
		check (include_in_search_p in (''t'',''f''));

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


-- deref_plpgsql_function
create or replace function inline_0 ()
returns integer as '
declare
	v_count		 integer;
begin
	select count(*) into v_count from user_tab_columns
	where lower(table_name) = ''im_dynfield_widgets'' and lower(column_name) = ''deref_plpgsql_function'';
	IF 0 != v_count THEN return 0; END IF;

	alter table im_dynfield_widgets
	add deref_plpgsql_function varchar(100);
	alter table im_dynfield_widgets alter column deref_plpgsql_function set default ''im_name_from_id'';
	update im_dynfield_widgets set deref_plpgsql_function = ''im_name_from_id'';

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

