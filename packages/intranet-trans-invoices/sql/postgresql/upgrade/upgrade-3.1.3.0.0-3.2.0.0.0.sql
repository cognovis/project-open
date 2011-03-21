-- upgrade-3.1.3.0.0-3.2.0.0.0.sql

SELECT acs_log__debug('/packages/intranet-trans-invoices/sql/postgresql/upgrade/upgrade-3.1.3.0.0-3.2.0.0.0.sql','');


-- Rename the im_price_idx to im_trans_price_idx

create or replace function inline_1 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from pg_indexes
	where indexname = ''im_price_idx'';
	if v_count = 0 then return 0; end if;

	drop index im_price_idx;

	return 0;
end;' language 'plpgsql';
select inline_1 ();
drop function inline_1();



create or replace function inline_1 ()
returns integer as '
declare
	v_count		integer;
begin
	select count(*) into v_count from pg_indexes
	where indexname = ''im_trans_price_idx'';
	if v_count > 0 then return 0; end if;

	create unique index im_trans_price_idx on im_trans_prices (
		uom_id, company_id, task_type_id, target_language_id,
		source_language_id, subject_area_id, currency
	);

	return 0;
end;' language 'plpgsql';
select inline_1 ();
drop function inline_1();

