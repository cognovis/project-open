-- upgrade-3.3.0.0.0-3.3.0.1.0.sql

SELECT acs_log__debug('/packages/intranet-invoices/sql/postgresql/upgrade/upgrade-3.3.0.0.0-3.3.0.1.0.sql','');

\i ../../../../intranet-core/sql/postgresql/upgrade/upgrade-3.0.0.0.first.sql


create or replace function inline_0 ()
returns integer as '
declare
	v_count	integer;
begin
	select count(*) into v_count from user_tab_columns
	where table_name = ''IM_INVOICES'' and column_name = ''DISCOUNT_PERC'';
	IF v_count > 0 THEN return 0; END IF;

	alter table im_invoices add discount_perc numeric(12,2);
	alter table im_invoices add discount_text text;
	alter table im_invoices ALTER discount_perc set default 0;
	update im_invoices set discount_perc = 0 where discount_perc is null;

	alter table im_invoices add surcharge_perc numeric(12,2);
	alter table im_invoices add surcharge_text text;
	alter table im_invoices ALTER surcharge_perc set default 0;
	update im_invoices set surcharge_perc = 0 where surcharge_perc is null;

	alter table im_invoices add deadline_start_date	timestamptz;
	alter table im_invoices add deadline_interval interval;

	return 0;
end;' language 'plpgsql';
SELECT inline_0();
DROP FUNCTION inline_0();


--------------------------------------------------------------
-- Category for canned note
-- alter table im_invoices add canned_note_id integer;

create or replace function inline_0 ()
returns integer as '
declare
	v_count	integer;
begin
	select count(*) into v_count from acs_object_type_tables
	where table_name = ''im_invoices'';
	IF v_count > 0 THEN return 0; END IF;

	insert into acs_object_type_tables (object_type,table_name,id_column)
	values (''im_invoice'', ''im_invoices'', ''invoice_id'');

	return 0;
end;' language 'plpgsql';
SELECT inline_0();
DROP FUNCTION inline_0();



select im_dynfield_attribute__new (
	null,				-- widget_id
	'im_dynfield_attribute',	-- object_type
	now(),				-- creation_date
	null,				-- creation_user
	null,				-- creation_ip
	null,				-- context_id

	'im_invoice',			-- attribute_object_type
	'canned_note_id',		-- attribute name
	0,
	0,
	null,
	'integer',
	'#intranet-invoices.Canned_Note#',	-- pretty name
	'#intranet-invoices.Canned_Note#',	-- pretty plural
	'integer',			-- Widget (dummy)
	'f',
	'f'
);



-- 11600-11699	Intranet Invoice Canned Notes

create or replace view im_invoice_canned_notes as
select
	category_id as canned_note_id,
	category as canned_note_category,
	aux_string1 as canned_note
from im_categories
where category_type = 'Intranet Invoice Canned Notes';


SELECT im_category_new(11600, 'Dummy Canned Note', 'Intranet Invoice Canned Note');
update im_categories set aux_string1 = 'Message text for Dummy Canned Note' where category_id = 11600;

