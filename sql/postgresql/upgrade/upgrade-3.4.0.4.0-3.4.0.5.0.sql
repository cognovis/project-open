-- upgrade-3.4.0.2.0-3.4.0.3.0.sql


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select	count(*) into v_count
	from	user_tab_columns 
	where	lower(table_name) = ''im_dynfield_type_attribute_map'' and 
		lower(column_name) = ''help_text'';
	IF 0 != v_count THEN return 0; END IF;

	alter table im_dynfield_type_attribute_map
	add column help_text text;

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select	count(*) into v_count
	from	user_tab_columns 
	where	lower(table_name) = ''im_dynfield_type_attribute_map'' and 
		lower(column_name) = ''section_heading'';
	IF 0 != v_count THEN return 0; END IF;

	alter table im_dynfield_type_attribute_map
	add column section_heading text;

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select	count(*) into v_count
	from	user_tab_columns 
	where	lower(table_name) = ''im_dynfield_type_attribute_map'' and 
		lower(column_name) = ''default_value'';
	IF 0 != v_count THEN return 0; END IF;

	alter table im_dynfield_type_attribute_map
	add column default_value text;

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
