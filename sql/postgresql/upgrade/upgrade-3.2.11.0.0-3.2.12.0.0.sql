-- upgrade-3.2.11.0.0-3.2.12.0.0.sql

-- Category for canned note
-- alter table im_invoices add canned_note_id integer;



insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_invoice', 'im_invoices', 'invoice_id');




create or replace function im_dynfield_attribute__new (
        integer, varchar, timestamptz, integer, varchar, integer,
        varchar, varchar, integer, integer, varchar,
        varchar, varchar, varchar, varchar, char, char
) returns integer as '
DECLARE
        p_attribute_id          alias for $1;
        p_object_type           alias for $2;
        p_creation_date         alias for $3;
        p_creation_user         alias for $4;
        p_creation_ip           alias for $5;
        p_context_id            alias for $6;

        p_attribute_object_type alias for $7;
        p_attribute_name        alias for $8;
        p_min_n_values          alias for $9;
        p_max_n_values          alias for $10;
        p_default_value         alias for $11;

        p_datatype              alias for $12;
        p_pretty_name           alias for $13;
        p_pretty_plural         alias for $14;
        p_widget_name           alias for $15;
        p_deprecated_p          alias for $16;
        p_already_existed_p     alias for $17;

        v_acs_attribute_id      integer;
        v_attribute_id          integer;
        v_table_name            varchar;
BEGIN
        select table_name into v_table_name
        from acs_object_types where object_type = p_attribute_object_type;

        v_acs_attribute_id := acs_attribute__create_attribute (
                p_attribute_object_type,
                p_attribute_name,
                p_datatype,
                p_pretty_name,
                p_pretty_plural,
                v_table_name,           -- table_name
                null,                   -- column_name
                p_default_value,
                p_min_n_values,
                p_max_n_values,
                null,                   -- sort order
                ''type_specific'',      -- storage
                ''f''                   -- static_p
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
        return v_attribute_id;
end;' language 'plpgsql';



select im_dynfield_attribute__new (
        null,                   -- widget_id
        'im_dynfield_attribute', -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id

        'im_invoice',           -- attribute_object_type
        'canned_note_id',       -- attribute name
        0,
        0,
        null,
        'integer',
        '#intranet-invoices.Canned_Note#',    -- pretty name
        '#intranet-invoices.Canned_Note#',    -- pretty plural
        'integer',              -- Widget (dummy)
        'f',
        'f'
);



-- 11600-11699  Intranet Invoice Canned Notes


create or replace view im_invoice_canned_notes as
select
        category_id as canned_note_id,
        category as canned_note_category,
	aux_string1 as canned_note
from im_categories
where category_type = 'Intranet Invoice Canned Notes';


insert into im_categories (category_id, category, category_type, aux_string1)
values (11600, 'Dummy Canned Note', 'Intranet Invoice Canned Note', 'Message text for Dummy Canned Note');

-- reserved through 11699

