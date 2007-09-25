-- upgrade-3.2.11.0.0-3.2.12.0.0.sql

-- Category for canned note
-- alter table im_invoices add canned_note_id integer;



insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_invoice', 'im_invoices', 'invoice_id');



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

