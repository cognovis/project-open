-- upgrade-3.2.5.0.0-3.2.6.0.0.sql

SELECT acs_log__debug('/packages/intranet-dynfield/sql/postgresql/upgrade/upgrade-3.2.5.0.0-3.2.6.0.0.sql','');


create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count
	from im_dynfield_widgets where widget_name = ''currencies'';
	IF 0 != v_count THEN return 0; END IF;

	PERFORM im_dynfield_widget__new (
		null,			-- widget_id
		''im_dynfield_widget'',	-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
	
		''currencies'',		-- widget_name
		''#intranet-core.Currency#'',	-- pretty_name
		''#intranet-core.Currencies#'',	-- pretty_plural
		10007,			-- storage_type_id
		''string'',		-- acs_datatype
		''generic_sql'',		-- widget
		''char(3)'',		-- sql_datatype
		''{custom {sql {select iso, iso from currency_codes where supported_p = ''''t'''' }}}''
	);

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count
	from im_dynfield_widgets where widget_name = ''category_payment_method'';
	IF 0 != v_count THEN return 0; END IF;

	PERFORM im_dynfield_widget__new (
		null,			-- widget_id
		''im_dynfield_widget'',	-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
	
		''category_payment_method'',		-- widget_name
		''#intranet-core.Payment_Method#'',	-- pretty_name
		''#intranet-core.Payment_Methods#'',	-- pretty_plural
		10007,			-- storage_type_id
		''integer'',		-- acs_datatype
		''im_category_tree'',	-- widget
		''integer'',		-- sql_datatype
		''{custom {category_type "Intranet Invoice Payment Method"}}'' -- parameters
	);

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
	where lower(table_name) = ''im_dynfield_type_attribute_map'';
	IF 0 != v_count THEN return 0; END IF;

	create table im_dynfield_type_attribute_map (
		attribute_id		integer
					constraint im_dynfield_type_attr_map_attr_fk
					references acs_objects,
		object_type_id	integer
					constraint im_dynfield_type_attr_map_otype_nn
					not null
					constraint im_dynfield_type_attr_map_otype_fk
					references im_categories,
		display_mode		varchar(10)
					constraint im_dynfield_type_attr_map_dmode_nn
					not null
					constraint im_dynfield_type_attr_map_dmode_ck
					check (display_mode in (''edit'', ''display'', ''none'')),
		unique (attribute_id, object_type_id)
	);

	return 0;

end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


comment on table im_dynfield_type_attribute_map is '
This map allows us to specify whether a DynField attribute should
appear in a Edit/NewPage of an object, and whether it should appear
in edit or display mode.
The table maps the objects type_id (such as project_type_id, company_type_id
etc.) to the "display_mode" for the DynField attribute.
The display mode is "edit" if there is no entry in this map table.
';





-------------------------------------------------------------
-- DynField Fields
--

create or replace function inline_0 ()
returns integer as '
declare
	v_attrib_name	varchar;	
	v_attrib_pretty	varchar;
	v_object_name		varchar;
	v_table_name		varchar;
	v_acs_attrib_id	integer;	
	v_attrib_id		integer;
	v_count		integer;
begin
	v_attrib_name := ''default_vat'';
	v_attrib_pretty := ''Default VAT'';
	v_object_name = ''im_company'';
	v_table_name = ''im_companies'';

	select count(*) into v_count from acs_attributes where attribute_name = v_attrib_name;
	IF 0 != v_count THEN return 0; END IF;

	v_acs_attrib_id := acs_attribute__create_attribute (
		v_object_name,
		v_attrib_name,
		''integer'',
		v_attrib_pretty,
		v_attrib_pretty,
		v_table_name,
		NULL, NULL, ''0'', ''1'',
		NULL, NULL, NULL
	);
	v_attrib_id := acs_object__new (
		null,
		''im_dynfield_attribute'',
		now(),
		null, null, null
	);
	insert into im_dynfield_attributes (
		attribute_id, acs_attribute_id, widget_name, deprecated_p
	) values (
		v_attrib_id, v_acs_attrib_id, ''textbox_small'', ''f''
	);
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




create or replace function inline_0 ()
returns integer as '
declare
	v_attrib_name		varchar;	v_attrib_pretty		varchar;
	v_object_name		varchar;	v_table_name		varchar;
	v_widget_name		varchar;	v_data_type		varchar;

	v_acs_attrib_id	integer;	
	v_attrib_id		integer;
	v_count		integer;
begin
	v_attrib_name := ''default_invoice_template_id'';
	v_attrib_pretty := ''Default Invoice Template'';
	v_object_name = ''im_company'';
	v_table_name = ''im_companies'';
	v_data_type = ''integer'';
	v_widget_name = ''category_invoice_template'';

	select count(*) into v_count from acs_attributes
	where attribute_name = v_attrib_name;
	IF 0 != v_count THEN return 0; END IF;

	v_acs_attrib_id := acs_attribute__create_attribute (
		v_object_name,
		v_attrib_name,
		v_data_type,
		v_attrib_pretty,
		v_attrib_pretty,
		v_table_name,
		NULL, NULL, ''0'', ''1'',
		NULL, NULL, NULL
	);
	v_attrib_id := acs_object__new (
		null,
		''im_dynfield_attribute'',
		now(),
		null, null, null
	);
	insert into im_dynfield_attributes (
		attribute_id, acs_attribute_id, widget_name, deprecated_p
	) values (
		v_attrib_id, v_acs_attrib_id, v_widget_name, ''f''
	);
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();





create or replace function inline_0 ()
returns integer as '
declare
	v_attrib_name		varchar;	v_attrib_pretty		varchar;
	v_object_name		varchar;	v_table_name		varchar;
	v_widget_name		varchar;	v_data_type		varchar;

	v_acs_attrib_id	integer;	
	v_attrib_id		integer;
	v_count		integer;
begin
	v_attrib_name := ''default_payment_method_id'';
	v_attrib_pretty := ''Default Payment Method'';
	v_object_name = ''im_company'';
	v_table_name = ''im_companies'';
	v_data_type = ''integer'';
	v_widget_name = ''category_payment_method'';

	select count(*) into v_count from acs_attributes
	where attribute_name = v_attrib_name;
	IF 0 != v_count THEN return 0; END IF;

	v_acs_attrib_id := acs_attribute__create_attribute (
		v_object_name,
		v_attrib_name,
		v_data_type,
		v_attrib_pretty,
		v_attrib_pretty,
		v_table_name,
		NULL, NULL, ''0'', ''1'',
		NULL, NULL, NULL
	);
	v_attrib_id := acs_object__new (
		null,
		''im_dynfield_attribute'',
		now(),
		null, null, null
	);
	insert into im_dynfield_attributes (attribute_id, acs_attribute_id, widget_name, deprecated_p
	) values (v_attrib_id, v_acs_attrib_id, v_widget_name, ''f'');
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



create or replace function inline_0 ()
returns integer as '
declare
	v_attrib_name		varchar;	v_attrib_pretty		varchar;
	v_object_name		varchar;	v_table_name		varchar;
	v_widget_name		varchar;	v_data_type		varchar;

	v_acs_attrib_id	integer;	
	v_attrib_id		integer;
	v_count		integer;
begin
	v_attrib_name := ''default_payment_days'';
	v_attrib_pretty := ''Default Payment Days'';
	v_object_name = ''im_company'';
	v_table_name = ''im_companies'';
	v_data_type = ''integer'';
	v_widget_name = ''textbox_small'';

	select count(*) into v_count
	from acs_attributes
	where attribute_name = v_attrib_name;
	IF 0 != v_count THEN return 0; END IF;

	v_acs_attrib_id := acs_attribute__create_attribute (
		v_object_name,
		v_attrib_name,
		v_data_type,
		v_attrib_pretty,
		v_attrib_pretty,
		v_table_name,
		NULL, NULL, ''0'', ''1'',
		NULL, NULL, NULL
	);
	v_attrib_id := acs_object__new (
		null,
		''im_dynfield_attribute'',
		now(),
		null, null, null
	);
	insert into im_dynfield_attributes (attribute_id, acs_attribute_id, widget_name, deprecated_p
	) values (v_attrib_id, v_acs_attrib_id, v_widget_name, ''f'');
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



create or replace function inline_0 ()
returns integer as '
declare
	v_attrib_name		varchar;	v_attrib_pretty		varchar;
	v_object_name		varchar;	v_table_name		varchar;
	v_widget_name		varchar;	v_data_type		varchar;

	v_acs_attrib_id	integer;	
	v_attrib_id		integer;
	v_count		integer;
begin
	v_attrib_name := ''default_bill_template_id'';
	v_attrib_pretty := ''Default Bill Template'';
	v_object_name = ''im_company'';
	v_table_name = ''im_companies'';
	v_data_type = ''integer'';
	v_widget_name = ''category_invoice_template'';

	select count(*) into v_count
	from acs_attributes
	where attribute_name = v_attrib_name;
	IF 0 != v_count THEN return 0; END IF;

	v_acs_attrib_id := acs_attribute__create_attribute (
		v_object_name,
		v_attrib_name,
		v_data_type,
		v_attrib_pretty,
		v_attrib_pretty,
		v_table_name,
		NULL, NULL, ''0'', ''1'',
		NULL, NULL, NULL
	);
	v_attrib_id := acs_object__new (
		null,
		''im_dynfield_attribute'',
		now(),
		null, null, null
	);
	insert into im_dynfield_attributes (attribute_id, acs_attribute_id, widget_name, deprecated_p
	) values (v_attrib_id, v_acs_attrib_id, v_widget_name, ''f'');
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



create or replace function inline_0 ()
returns integer as '
declare
	v_attrib_name		varchar;	v_attrib_pretty		varchar;
	v_object_name		varchar;	v_table_name		varchar;
	v_widget_name		varchar;	v_data_type		varchar;

	v_acs_attrib_id	integer;	
	v_attrib_id		integer;
	v_count		integer;
begin
	v_attrib_name := ''default_po_template_id'';
	v_attrib_pretty := ''Default Purchase Order Template'';
	v_object_name = ''im_company'';
	v_table_name = ''im_companies'';
	v_data_type = ''integer'';
	v_widget_name = ''category_invoice_template'';

	select count(*) into v_count
	from acs_attributes
	where attribute_name = v_attrib_name;
	IF 0 != v_count THEN return 0; END IF;

	v_acs_attrib_id := acs_attribute__create_attribute (
		v_object_name,
		v_attrib_name,
		v_data_type,
		v_attrib_pretty,
		v_attrib_pretty,
		v_table_name,
		NULL, NULL, ''0'', ''1'',
		NULL, NULL, NULL
	);
	v_attrib_id := acs_object__new (
		null,
		''im_dynfield_attribute'',
		now(),
		null, null, null
	);
	insert into im_dynfield_attributes (attribute_id, acs_attribute_id, widget_name, deprecated_p
	) values (v_attrib_id, v_acs_attrib_id, v_widget_name, ''f'');
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



create or replace function inline_0 ()
returns integer as '
declare
	v_attrib_name		varchar;	v_attrib_pretty		varchar;
	v_object_name		varchar;	v_table_name		varchar;
	v_widget_name		varchar;	v_data_type		varchar;

	v_acs_attrib_id	integer;	
	v_attrib_id		integer;
	v_count		integer;
begin
	v_attrib_name := ''default_delnote_template_id'';
	v_attrib_pretty := ''Default Delivery Note Template'';
	v_object_name = ''im_company'';
	v_table_name = ''im_companies'';
	v_data_type = ''integer'';
	v_widget_name = ''category_invoice_template'';

	select count(*) into v_count
	from acs_attributes
	where attribute_name = v_attrib_name;
	IF 0 != v_count THEN return 0; END IF;

	v_acs_attrib_id := acs_attribute__create_attribute (
		v_object_name,
		v_attrib_name,
		v_data_type,
		v_attrib_pretty,
		v_attrib_pretty,
		v_table_name,
		NULL, NULL, ''0'', ''1'',
		NULL, NULL, NULL
	);
	v_attrib_id := acs_object__new (
		null,
		''im_dynfield_attribute'',
		now(),
		null, null, null
	);
	insert into im_dynfield_attributes (attribute_id, acs_attribute_id, widget_name, deprecated_p
	) values (v_attrib_id, v_acs_attrib_id, v_widget_name, ''f'');
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



