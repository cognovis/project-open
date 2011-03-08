-- upgrade-3.2.10.0.0-3.2.11.0.0.sql

SELECT acs_log__debug('/packages/intranet-exchange-rate/sql/postgresql/upgrade/upgrade-3.2.10.0.0-3.2.11.0.0.sql','');

-- Fills ALL "holes" in the im_exchange_rates table.
-- Populate im_exchange_rates for the next 5 years
create or replace function im_exchange_rate_fill_holes (varchar)
returns integer as '
DECLARE
    p_currency			alias for $1;
    v_max			integer;
    v_start_date		date;
    v_rate			numeric;
    row2			RECORD;
    exists			integer;
BEGIN
    RAISE NOTICE ''im_exchange_rate_fill_holes: cur=%'', p_currency;

    v_start_date := to_date(''2004-01-01'', ''YYYY-MM-DD'');
    v_max := 365 * 5;

    -- Loop through all dates and check if there
    -- is a hole (no entry for a date)
    FOR row2 IN
	select	im_day_enumerator as day
	from	im_day_enumerator(v_start_date, v_start_date + v_max)
		LEFT OUTER JOIN (
			select	*
			from	im_exchange_rates 
			where	currency = p_currency
		) ex on (im_day_enumerator = ex.day)
	where	ex.rate is null
    LOOP
	-- RAISE NOTICE ''im_exchange_rate_fill_holes: day=%'', row2.day;
	-- get the latest manually entered exchange rate
	select	rate
	into	v_rate
	from	im_exchange_rates 
	where	day = (
			select	max(day) 
			from	im_exchange_rates 
			where	day < row2.day
				and currency = p_currency
				and manual_p = ''t''
		      )
		and currency = p_currency;
	-- RAISE NOTICE ''im_exchange_rate_fill_holes: rate=%'', v_rate;
	-- use the latest exchange rate for the next few years...
	select	count(*) into exists
	from im_exchange_rates 
	where day=row2.day and currency=p_currency;
	IF exists > 0 THEN
		update im_exchange_rates
		set	rate = v_rate,
			manual_p = ''f''
		where	day = row2.day
			and currency = p_currency;
	ELSE
	-- RAISE NOTICE ''im_exchange_rate_fill_holes: day=%, cur=%, rate=%, x=%'',row2.day, p_currency, v_rate, exists;
		insert into im_exchange_rates (
			day, rate, currency, manual_p
		) values (
			row2.day, v_rate, p_currency, ''f''		
		);
	END IF;

    END LOOP;	

    return 0;
end;' language 'plpgsql';
-- select im_exchange_rate_fill_holes ();




