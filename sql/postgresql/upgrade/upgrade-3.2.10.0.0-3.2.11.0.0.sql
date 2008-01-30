-- upgrade-3.2.10.0.0-3.2.11.0.0.sql

create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
    select	count(*) into v_count
    from	user_tab_columns
    where	table_name = ''IM_INVOICES'' and column_name = ''DISCOUNT_PERC'';

    IF v_count = 0 THEN
		alter table im_invoices
		add	discount_perc	   numeric(12,2);
		alter table im_invoices
		add	discount_text	   text;
		alter table im_invoices 
		ALTER discount_perc set default 0;
		update im_invoices set discount_perc = 0 where discount_perc is null;
		
		alter table im_invoices
		add	surcharge_perc	  numeric(12,2);
		alter table im_invoices
		add	surcharge_text	  text;
		alter table im_invoices 
		ALTER surcharge_perc set default 0;
		update im_invoices set surcharge_perc = 0 where surcharge_perc is null;
		
		alter table im_invoices
		add	   deadline_start_date	timestamptz;
		alter table im_invoices
		add	   deadline_interval	interval;
    END IF;

    return 0;
end;' language 'plpgsql';
select inline_0 ();





