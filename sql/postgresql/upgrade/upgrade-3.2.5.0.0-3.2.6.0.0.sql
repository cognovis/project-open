-- upgrade-3.2.5.0.0-3.2.6.0.0.sql


-------------------------------------------------------------
-- DynField Fields
--

create or replace function inline_0 ()
returns integer as '
declare
        v_attrib_name           varchar;        
	v_attrib_pretty         varchar;
	v_object_name		varchar;
	v_table_name		varchar;
        v_acs_attrib_id         integer;        
	v_attrib_id             integer;
        v_count                 integer;
begin
        v_attrib_name := ''default_vat'';
        v_attrib_pretty := ''Default VAT'';
	v_object_name = ''im_company'';
	v_table_name = ''im_companies'';

        select count(*) into v_count
        from acs_attributes
        where attribute_name = v_attrib_name;
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
        v_attrib_name           varchar;        v_attrib_pretty         varchar;
	v_object_name		varchar;	v_table_name		varchar;
	v_widget_name		varchar;	v_data_type		varchar;

        v_acs_attrib_id         integer;        
	v_attrib_id             integer;
        v_count                 integer;
begin
        v_attrib_name := ''default_invoice_template_id'';
        v_attrib_pretty := ''Default Invoice Template'';
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
        v_attrib_name           varchar;        v_attrib_pretty         varchar;
	v_object_name		varchar;	v_table_name		varchar;
	v_widget_name		varchar;	v_data_type		varchar;

        v_acs_attrib_id         integer;        
	v_attrib_id             integer;
        v_count                 integer;
begin
        v_attrib_name := ''default_payment_method_id'';
        v_attrib_pretty := ''Default Payment Method'';
	v_object_name = ''im_company'';
	v_table_name = ''im_companies'';
	v_data_type = ''integer'';
	v_widget_name = ''category_payment_method'';

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
        v_attrib_name           varchar;        v_attrib_pretty         varchar;
	v_object_name		varchar;	v_table_name		varchar;
	v_widget_name		varchar;	v_data_type		varchar;

        v_acs_attrib_id         integer;        
	v_attrib_id             integer;
        v_count                 integer;
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
        v_attrib_name           varchar;        v_attrib_pretty         varchar;
	v_object_name		varchar;	v_table_name		varchar;
	v_widget_name		varchar;	v_data_type		varchar;

        v_acs_attrib_id         integer;        
	v_attrib_id             integer;
        v_count                 integer;
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
        v_attrib_name           varchar;        v_attrib_pretty         varchar;
	v_object_name		varchar;	v_table_name		varchar;
	v_widget_name		varchar;	v_data_type		varchar;

        v_acs_attrib_id         integer;        
	v_attrib_id             integer;
        v_count                 integer;
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
        v_attrib_name           varchar;        v_attrib_pretty         varchar;
	v_object_name		varchar;	v_table_name		varchar;
	v_widget_name		varchar;	v_data_type		varchar;

        v_acs_attrib_id         integer;        
	v_attrib_id             integer;
        v_count                 integer;
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






