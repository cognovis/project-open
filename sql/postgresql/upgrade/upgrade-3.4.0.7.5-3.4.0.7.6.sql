-- upgrade-3.4.0.7.5-3.4.0.7.6.sql

SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-3.4.0.7.5-3.4.0.7.6.sql','');


-- Returns a TCL list of company_id suitable to stuff into a
-- TCL hash array of all companies associated to a specific user.
create or replace function im_company_list_for_user_html (integer) returns varchar as '
DECLARE
	p_user_id	alias for $1;

	v_html		varchar;
	row		RECORD;
BEGIN
	v_html := '''';
	FOR row IN
		select	c.company_id
		from	im_companies c,
			acs_rels r
		where	r.object_id_one = c.company_id and
			r.object_id_two = p_user_id
		order by
			lower(c.company_name)
	LOOP
		IF '''' != v_html THEN v_html := v_html || '' ''; END IF;
		v_html := v_html || row.company_id;
	END LOOP;

	return v_html;
end;' language 'plpgsql';

