-- upgrade-4.0.3.5.1-4.0.3.5.2.sql

SELECT acs_log__debug('/packages/intranet-riskmanagement/sql/postgresql/upgrade/upgrade-4.0.3.5.1-4.0.3.5.2.sql','');


-----------------------------------------------------------
-- PL/SQL functions to Create and Delete risks and to get
-- the name of a specific risk.
--
create or replace function im_risk__name(integer)
returns varchar as $body$
DECLARE
	p_risk_id		alias for $1;
	v_name			varchar;
BEGIN
	select	risk_name
	into	v_name from im_risks
	where	risk_id = p_risk_id;

	return v_name;
end; $body$ language 'plpgsql';


