-- upgrade-3.4.0.1.0-3.4.0.2.0.sql



update im_dynfield_layout set page_url = 'default' where page_url = '';
update im_dynfield_layout_pages set page_url = 'default' where page_url = '';


create or replace function im_dynfield_attribute__new_only_dynfield (
        integer, varchar, timestamptz, integer, varchar, integer,
        integer, varchar, char(1), char(1)
) returns integer as '
DECLARE
        p_attribute_id          alias for $1;
        p_object_type           alias for $2;
        p_creation_date         alias for $3;
        p_creation_user         alias for $4;
        p_creation_ip           alias for $5;
        p_context_id            alias for $6;

        p_acs_attribute_id      alias for $7;
        p_widget_name           alias for $8;
        p_deprecated_p          alias for $9;
        p_already_existed_p     alias for $10;

        v_attribute_id          integer;
BEGIN
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
                v_attribute_id, p_acs_attribute_id, p_widget_name,
                p_deprecated_p, p_already_existed_p
        );
        return v_attribute_id;
end;' language 'plpgsql';


alter table im_dynfield_attributes
add column also_hard_coded_p	char(1) default 'f'
				constraint im_dynfield_attributes_also_hard_coded_ch
				check (also_hard_coded_p in ('t','f'))
;



-- Make acs_attribute unique, so that no two dynfield_attributes can reference the same acs_attrib.
alter table im_dynfield_attributes add constraint
im_dynfield_attributes_acs_attribute_un UNIQUE (acs_attribute_id);





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
	select table_name into v_table_name
	from acs_object_types where object_type = p_attribute_object_type;

	select attribute_id into v_acs_attribute_id from acs_attributes
	where object_type = p_attribute_object_type and attribute_name = p_attribute_name;

	IF v_acs_attribute_id is null THEN
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
	END IF;

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

