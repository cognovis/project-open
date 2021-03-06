-- /packages/intranet-exchange-rate/sql/postgresql/update/upgrade-3.3.0.0.0-3.3.0.0.1.sql
--
-- ]project-open[ Exchange Rate Module
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
-- @author klaus.hofeditz@project-open.com

----------------------------------------------------

SELECT acs_log__debug('/packages/intranet-exchange-rate/sql/postgresql/upgrade/upgrade-3.3.2.0.1-3.3.2.0.2.sql','');

-- Updated "fill_holes" updating until 2015
-- Still ugly somehow...
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
    v_max := 365 * 11;

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
	RAISE NOTICE ''im_exchange_rate_fill_holes: day=%, cur=%, rate=%, x=%'',row2.day, p_currency, v_rate, exists;
		insert into im_exchange_rates (
			day, rate, currency, manual_p
		) values (
			row2.day, v_rate, p_currency, ''f''		
		);
	END IF;

    END LOOP;	

    return 0;
end;' language 'plpgsql';


-- Fills ALL "holes" with the new fill_holes procedure.
create or replace function inline_0 ()
returns integer as '
DECLARE
	v_max			integer;
	v_start_date		date;
	v_rate			numeric;
	v_exists_p		integer;

	row			RECORD;
BEGIN
	FOR row IN
		select	iso
		from	currency_codes
		where	supported_p = ''t''
	    UNION
	        select	''USD''
	LOOP
		PERFORM im_exchange_rate_fill_holes (row.iso);
	END LOOP;

	return 0;
end;' language 'plpgsql';
select inline_0();
drop function inline_0();
