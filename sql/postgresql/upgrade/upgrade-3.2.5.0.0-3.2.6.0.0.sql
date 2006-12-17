-- upgrade-3.2.5.0.0-3.2.6.0.0.sql

-------------------------------------------------------------
-- Users Admin Menu
--


-- -------------------------------------------------------
-- Setup an invisible Users Admin menu
-- This can be extended later by other modules
-- with more Admin Links
--

create or replace function inline_0 ()
returns integer as '
declare
        -- Menu IDs
        v_menu                  integer;
        v_admin_menu            integer;
        v_main_menu             integer;
BEGIN
    select menu_id
    into v_main_menu
    from im_menus
    where label = ''users'';

    -- Main admin menu - just an invisible top-menu
    -- for all admin entries links under Users
    v_admin_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''users_admin'',        -- label
        ''Users Admin'',        -- name
        ''/intranet-core/'',    -- url
        90,                     -- sort_order
        v_main_menu,            -- parent_menu_id
        ''0''                   -- p_visible_tcl
    );

    return 0;
end;' language 'plpgsql';

select inline_0 ();
drop function inline_0 ();




create or replace function inline_1 ()
returns integer as '
declare
      v_menu                  integer;
      v_users_admin_menu      integer;

      v_employees             integer;
      v_accounting            integer;
      v_senman                integer;
      v_customers             integer;
      v_freelancers           integer;
      v_proman                integer;
      v_admins                integer;
      v_reg_users             integer;
begin
    select group_id into v_admins from groups where group_name = ''P/O Admins'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';
    select group_id into v_proman from groups where group_name = ''Project Managers'';
    select group_id into v_accounting from groups where group_name = ''Accounting'';
    select group_id into v_employees from groups where group_name = ''Employees'';
    select group_id into v_customers from groups where group_name = ''Customers'';
    select group_id into v_freelancers from groups where group_name = ''Freelancers'';
    select group_id into v_reg_users from groups where group_name = ''Registered Users'';

    select menu_id
    into v_users_admin_menu
    from im_menus
    where label=''users_admin'';

    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''users_admin_csv'',    -- label
        ''Export Users Cube'',  -- name
        ''/intranet-dw-light/users.csv'',  -- url
        10,                     -- sort_order
        v_users_admin_menu,     -- parent_menu_id
        null                    -- p_visible_tcl
    );

    return 0;
end;' language 'plpgsql';
select inline_1 ();
drop function inline_1 ();









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






