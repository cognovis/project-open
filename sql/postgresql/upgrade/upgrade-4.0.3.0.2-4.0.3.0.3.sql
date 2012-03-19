-- upgrade-4.0.3.0.1-4.0.3.0.2.sql

SELECT acs_log__debug('/packages/intranet-audit/sql/postgresql/upgrade/upgrade-4.0.3.0.2-4.0.3.0.3.sql','');


-- Extract the value of a specific field from an audit_value
create or replace function im_audit_value (text, text)
returns text as $body$
DECLARE
	p_audit_value	alias for $1;
	p_var_name	alias for $2;

	v_expr		text;
	v_result	text;
BEGIN
	v_expr := p_var_name || '\\t([^\\n]*)';
	RAISE NOTICE 'im_audit_value: v_expr=%', v_expr;

	select	substring(p_audit_value from v_expr) 
	into v_result from dual;

	IF '' = v_result THEN v_result := null; END IF;

	return v_result;
end; $body$ language 'plpgsql';

