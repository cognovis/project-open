-- upgrade-4.0.3.0.1-4.0.3.0.2.sql
SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-4.0.3.0.1-4.0.3.0.2.sql','');


-- Deal with PostgreSQL 8.4 tighter casting rules

create or replace function inline_0 ()
returns integer as $body$
declare
        v_version	varchar;
begin
	select substring(version() from '([0-9]+\\.[0-9]+)') into v_version;

	-- ignore older versions of PG
	IF '7.0' = v_version THEN return 70; END IF;
	IF '7.1' = v_version THEN return 71; END IF;
	IF '7.2' = v_version THEN return 72; END IF;
	IF '7.3' = v_version THEN return 73; END IF;
	IF '7.4' = v_version THEN return 74; END IF;
	IF '7.5' = v_version THEN return 75; END IF;
	IF '8.0' = v_version THEN return 80; END IF;
	IF '8.1' = v_version THEN return 81; END IF;
	IF '8.2' = v_version THEN return 82; END IF;
	IF '8.3' = v_version THEN return 83; END IF;

	CREATE OR REPLACE FUNCTION last_day(date)
	RETURNS date AS '
	DECLARE
	        p_date_in alias for $1;         -- date_id
		
        	v_date_out      date;
	begin		
        	select to_date(date_trunc('month',add_months(p_date_in,1))::text, 'YYYY-MM-DD'::text) - 1 into v_date_out;
        	return v_date_out;
	end;' LANGUAGE 'plpgsql';

end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


