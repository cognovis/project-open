-- /packages/intranet-exchange-rate/sql/postgresql/intranet-exchange-rate-create.sql
--
-- ]project[ Exchange Rate Module
-- Copyright (c) 2003-2004 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
-- @author frank.bergmann@project-open.com

----------------------------------------------------
-- Exchange rates of currencies with respect to the US dollar

create table im_exchange_rates (
	day			date
				constraint im_exchange_rates_nn
				not null,
	currency		char(3)
				constraint im_exchange_rates_currency_fk
				references currency_codes,
	rate			numeric(12,6),
	manual_p		char(1)
				constraint im_exchange_rates_manual_ck
				check (manual_p in ('t','f')),
        constraint im_exchange_rates_pk
        primary key (day,currency)
);

-- load data from 1999-01-01 until 2005-06-30
\i intranet-exchange-rate-data.sql

-- Populate im_exchange_rates for the next 5 years
create or replace function inline_0 ()
returns integer as '
DECLARE
    v_max			integer;
    v_i				integer;
    v_first_block_of_month      integer;
    v_rate			numeric;
    row				RECORD;
BEGIN
    v_max := 365 * 5;
    FOR row IN
        select	iso as currency
	from	currency_codes
	where	supported_p = ''t''
    LOOP
	-- get the latest manually entered exchange rate
	select	rate
	into	v_rate
	from	im_exchange_rates 
	where	day = (
			select max(day) 
			from im_exchange_rates 
			where currency = row.currency
		)
		and manual_p = ''t''
		and currency = row.currency;

	-- use the latest exchange rate for the next few years...
	FOR v_i IN 0..v_max-1 LOOP
	
		insert into im_exchange_rates (
			day, rate, currency, manual_p
		) values (
			to_date(''2005-07-01'',''YYYY-MM-DD'') + v_i,
			v_rate, row.currency, ''f''		
		);

	END LOOP;
    END LOOP;
    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


-- shortcut function to calculate the exchange rate for a
-- specific day. This function is relatively slow and should 
-- NOT be used within a SQL query loop. 
-- Instead, it is useful as a shortcut to convert a single
-- currency item.
--
create or replace function im_exchange_rate (date, char(3), char(3))
returns float as '
DECLARE
    p_day		alias for $1;
    p_from_cur		alias for $2;
    p_to_cur		alias for $3;

    v_from_rate		float;
    v_to_rate		float;
BEGIN
    -- Exchange rate of From-Currency to Dollar
    select	rate
    into	v_from_rate
    from	im_exchange_rates
    where	currency = p_from_cur
		and day = p_day;

    -- Exchange rate of Dollar to To-Currency
    select	rate
    into	v_to_rate
    from	im_exchange_rates
    where	currency = p_to_cur
		and day = p_day;

    return v_from_rate / v_to_rate;
end;' language 'plpgsql';

-- select im_exchange_rate(to_date('2005-07-01','YYYY-MM-DD'), 'EUR', 'USD');
