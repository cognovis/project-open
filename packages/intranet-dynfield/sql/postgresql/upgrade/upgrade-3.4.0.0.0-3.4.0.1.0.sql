-- upgrade-3.4.0.0.0-3.4.0.1.0.sql

SELECT acs_log__debug('/packages/intranet-dynfield/sql/postgresql/upgrade/upgrade-3.4.0.0.0-3.4.0.1.0.sql','');



---------------------------------------------------------
-- Setup DynField Widgets Data
---------------------------------------------------------

create or replace function im_dynfield_widget__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	varchar, varchar, varchar, integer, varchar, varchar, 
	varchar, varchar
) returns integer as '
DECLARE
	p_widget_id		alias for $1;
	p_object_type		alias for $2;
	p_creation_date 	alias for $3;
	p_creation_user 	alias for $4;
	p_creation_ip		alias for $5;
	p_context_id		alias for $6;

	p_widget_name		alias for $7;
	p_pretty_name		alias for $8;
	p_pretty_plural		alias for $9;
	p_storage_type_id	alias for $10;
	p_acs_datatype		alias for $11;
	p_widget		alias for $12;
	p_sql_datatype		alias for $13;
	p_parameters		alias for $14;

	v_widget_id		integer;
BEGIN
	v_widget_id := acs_object__new (
		p_widget_id,
		p_object_type,
		p_creation_date,
		p_creation_user,
		p_creation_ip,
		p_context_id
	);

	insert into im_dynfield_widgets (
		widget_id, widget_name, pretty_name, pretty_plural,
		storage_type_id, acs_datatype, widget, sql_datatype, parameters
	) values (
		v_widget_id, p_widget_name, p_pretty_name, p_pretty_plural,
		p_storage_type_id, p_acs_datatype, p_widget, p_sql_datatype, p_parameters
	);
	return v_widget_id;
end;' language 'plpgsql';


create or replace function im_dynfield_widget__delete (integer) returns integer as '
DECLARE
        p_widget_id             alias for $1;
BEGIN
	-- Erase the im_dynfield_widgets item associated with the id
	delete from im_dynfield_widgets
	where widget_id = p_widget_id;

	-- Erase all the privileges
	delete from acs_permissions
	where object_id = p_widget_id;

	PERFORM acs_object__del(v_widget_id);
        return 0;
end;' language 'plpgsql';


create or replace function im_dynfield_widget__name (integer) returns varchar as '
DECLARE
	p_widget_id	alias for $1;
	v_name		varchar;
BEGIN
	select  widget_name
	into    v_name
	from    im_dynfield_widgets
	where   widget_id = p_widget_id;

	return v_name;
end;' language 'plpgsql';


-- ------------------------------------------------------------------
-- Package
-- ------------------------------------------------------------------



create or replace function im_dynfield_attribute__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	varchar, varchar, integer, integer, varchar, 
	varchar, varchar, varchar, varchar, char, char
) returns integer as '
DECLARE
	p_attribute_id		alias for $1;
	p_object_type		alias for $2;
	p_creation_date 	alias for $3;
	p_creation_user 	alias for $4;
	p_creation_ip		alias for $5;
	p_context_id		alias for $6;

	p_attribute_object_type	alias for $7;
	p_attribute_name	alias for $8;
	p_min_n_values		alias for $9;
	p_max_n_values		alias for $10;
	p_default_value		alias for $11;

	p_datatype		alias for $12;
	p_pretty_name		alias for $13;
	p_pretty_plural		alias for $14;
	p_widget_name		alias for $15;
	p_deprecated_p		alias for $16;
	p_already_existed_p	alias for $17;

	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_table_name		varchar;
BEGIN
	-- Check for duplicate
	select	da.attribute_id into v_attribute_id
	from	acs_attributes aa, im_dynfield_attributes da 
	where	aa.attribute_id = da.acs_attribute_id and
		aa.attribute_name = p_attribute_name and aa.object_type = p_attribute_object_type;
	if v_attribute_id is not null then return v_attribute_id; end if;

	select table_name into v_table_name
	from acs_object_types where object_type = p_attribute_object_type;

	v_acs_attribute_id := acs_attribute__create_attribute (
		p_attribute_object_type,
		p_attribute_name,
		p_datatype,
		p_pretty_name,
		p_pretty_plural,
		v_table_name,		-- table_name
		null,			-- column_name
		p_default_value,
		p_min_n_values,
		p_max_n_values,
		null,			-- sort order
		''type_specific'',	-- storage
		''f''			-- static_p
	);

	v_attribute_id := acs_object__new (
		p_attribute_id,
		p_object_type,
		p_creation_date,
		p_creation_user,
		p_creation_ip,
		p_context_id
	);

	insert into im_dynfield_attributes (
		attribute_id, acs_attribute_id, widget_name,
		deprecated_p, already_existed_p
	) values (
		v_attribute_id, v_acs_attribute_id, p_widget_name,
		p_deprecated_p, p_already_existed_p
	);

	-- By default show the field for all object types
	insert into im_dynfield_type_attribute_map (attribute_id, object_type_id, display_mode)
	select	ida.attribute_id,
		c.category_id,
		''edit''
	from	im_dynfield_attributes ida,
		acs_attributes aa,
		acs_object_types aot,
		im_categories c
	where	ida.acs_attribute_id = aa.attribute_id and
		aa.object_type = aot.object_type and
		aot.type_category_type = c.category_type and
		aot.object_type = p_attribute_object_type and
		aa.attribute_name = p_attribute_name;

	return v_attribute_id;
end;' language 'plpgsql';






create or replace function im_dynfield_attribute__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	varchar, varchar, integer, integer, varchar, 
	varchar, varchar, varchar, varchar, char, char, char
) returns integer as '
DECLARE
	p_attribute_id		alias for $1;
	p_object_type		alias for $2;
	p_creation_date 	alias for $3;
	p_creation_user 	alias for $4;
	p_creation_ip		alias for $5;
	p_context_id		alias for $6;

	p_attribute_object_type	alias for $7;
	p_attribute_name	alias for $8;
	p_min_n_values		alias for $9;
	p_max_n_values		alias for $10;
	p_default_value		alias for $11;

	p_datatype		alias for $12;
	p_pretty_name		alias for $13;
	p_pretty_plural		alias for $14;
	p_widget_name		alias for $15;
	p_deprecated_p		alias for $16;
	p_already_existed_p	alias for $17;

	p_table_name		alias for $18;

	v_acs_attribute_id	integer;
	v_attribute_id		integer;

BEGIN
	-- Check for duplicate
	select	da.attribute_id into v_attribute_id
	from	acs_attributes aa, im_dynfield_attributes da 
	where	aa.attribute_id = da.acs_attribute_id and
		aa.attribute_name = p_attribute_name and aa.object_type = p_attribute_object_type;
	if v_attribute_id is not null then return v_attribute_id; end if;

	v_acs_attribute_id := acs_attribute__create_attribute (
		p_attribute_object_type,
		p_attribute_name,
		p_datatype,
		p_pretty_name,
		p_pretty_plural,
		p_table_name,		-- table_name
		null,			-- column_name
		p_default_value,
		p_min_n_values,
		p_max_n_values,
		null,			-- sort order
		''type_specific'',	-- storage
		''f''			-- static_p
	);

	v_attribute_id := acs_object__new (
		p_attribute_id,
		p_object_type,
		p_creation_date,
		p_creation_user,
		p_creation_ip,
		p_context_id
	);

	insert into im_dynfield_attributes (
		attribute_id, acs_attribute_id, widget_name,
		deprecated_p, already_existed_p
	) values (
		v_attribute_id, v_acs_attribute_id, p_widget_name,
		p_deprecated_p, p_already_existed_p
	);

	-- By default show the field for all object types
	insert into im_dynfield_type_attribute_map (attribute_id, object_type_id, display_mode)
	select	ida.attribute_id,
		c.category_id,
		''edit''
	from	im_dynfield_attributes ida,
		acs_attributes aa,
		acs_object_types aot,
		im_categories c
	where	ida.acs_attribute_id = aa.attribute_id and
		aa.object_type = aot.object_type and
		aot.type_category_type = c.category_type and
		aot.object_type = p_attribute_object_type and
		aa.attribute_name = p_attribute_name;

	return v_attribute_id;
end;' language 'plpgsql';





-- Delete a single attribute (if we know its ID...)
create or replace function im_dynfield_attribute__del (integer) returns integer as '
DECLARE
        p_attribute_id             alias for $1;

	v_acs_attribute_id	integer;
	v_acs_attribute_name	varchar;
	v_object_type		varchar;
BEGIN
	-- get the acs_attribute_id and object_type
	select
		fa.acs_attribute_id, 
		aa.object_type,
		aa.attribute_name
	into 
		v_acs_attribute_id, 
		v_object_type,
		v_acs_attribute_name
	from
		im_dynfield_attributes fa,
		acs_attributes aa
	where
		aa.attribute_id = fa.acs_attribute_id
		and fa.attribute_id = p_attribute_id;

	-- Erase the im_dynfield_attributes item associated with the id
	delete from im_dynfield_layout
	where attribute_id = p_attribute_id;

	-- Erase values for the im_dynfield_attribute item associated with the id
	delete from im_dynfield_attr_multi_value
	where attribute_id = p_attribute_id;

	delete from im_dynfield_attributes
	where attribute_id = p_attribute_id;

	PERFORM acs_attribute__drop_attribute(v_object_type, v_acs_attribute_name);
        return 0;
end;' language 'plpgsql';


create or replace function im_dynfield_attribute__name (integer) returns varchar as '
DECLARE
	p_attribute_id	alias for $1;
	v_name		varchar;
	v_acs_attribute_id	integer;
BEGIN
	-- get the acs_attribute_id
	select	acs_attribute_id
	into	v_acs_attribute_id
	from	im_dynfield_attributes
	where	attribute_id = p_attribute_id;

	select  attribute_name
	into	v_name
	from	acs_attributes
	where   attribute_id = v_acs_attribute_id;

	return v_name;
end;' language 'plpgsql';


-- return a string coma separated with multimap values
create or replace function im_dynfield_multimap_val_to_str (integer, integer, varchar) 
returns varchar as '
DECLARE
	p_attr_id		alias for $1;
	p_obj_id		alias for $2;
	p_widget_type		alias for $3;

	v_ret_string		varchar;
	v_value			im_dynfield_attr_multi_value.value%TYPE;
	v_cat_name		varchar;
	row			RECORD;
BEGIN
	v_ret_string := null;
	FOR row IN
		SELECT	v_value
		FROM	im_dynfield_attr_multi_value
		WHERE	attribute_id = p_attr_id
			AND object_id = p_obj_id
			AND value is not null
	LOOP 
		if v_ret_string is not null then 
			v_ret_string := v_ret_string || '', '';
		end if; 
	
		if widget_type = ''category_tree'' then
			select category.name(row.v_value) into v_cat_name from dual;
			v_ret_string := v_ret_string || v_cat_name;
		else
			v_ret_string := v_ret_string || row.v_value;
		end if;
	END LOOP;
		
	return v_ret_string;
end;' language 'plpgsql';

