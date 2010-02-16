-- /packages/intranet-exchange-rate/sql/postgresql/update/upgrade-3.4.0.8.3-3.4.0.8.4.sql
--
-- ]project-open[ Exchange Rate Module
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.

----------------------------------------------------

SELECT acs_log__debug('/packages/intranet-exchange-rate/sql/postgresql/upgrade/upgrade-3.4.0.8.3-3.4.0.8.4.sql','');



create or replace function inline_0 ()
returns integer as $body$
DECLARE
	v_count			integer;
BEGIN
	select count(*) into v_count from currency_codes
	where iso = 'ARS';
	IF v_count > 0 THEN return 1; END IF;

	insert into currency_codes VALUES ('ARS','Argentine Peso','t',NULL,100);

	return 0;
end;$body$ language 'plpgsql';
select inline_0();
drop function inline_0();
