-- upgrade-3.3.1.1.0-3.3.1.2.0.sql

SELECT acs_log__debug('/packages/intranet-hr/sql/postgresql/upgrade/upgrade-3.3.1.1.0-3.3.1.2.0.sql','');

create or replace function im_supervises_p (integer, integer)
returns char as '
DECLARE
	p_supervisor_id		alias for $1;
	p_user_id		alias for $2;

	v_user_id		integer;
	v_exists_p		char;
	v_count			integer;
BEGIN
	v_count := 0;
	v_user_id := p_user_id;

	WHILE v_count < 100 and v_user_id is not null LOOP
		IF v_user_id = p_supervisor_id THEN return ''t''; END IF;

		select	e.supervisor_id into v_user_id
		from	im_employees e
		where	e.employee_id = v_user_id;

		v_count := v_count + 1;
	END LOOP;

	return ''f'';
END;' language 'plpgsql';
