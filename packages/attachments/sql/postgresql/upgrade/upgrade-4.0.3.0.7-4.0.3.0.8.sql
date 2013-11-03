-- upgrade-4.0.3.0.7-4.0.3.0.8.sql

SELECT acs_log__debug('/packages/intranet-freelance/sql/postgresql/upgrade/upgrade-4.0.3.0.7-4.0.3.0.8.sql','');




-- Returns all skills for a person in one TCL string representing an array
create or replace function im_freelance_skill_id_list (integer)
returns varchar as $body$
declare
	p_user_id			alias for $1;
	v_skills			varchar;
	row				RECORD;
BEGIN
	v_skills := '';

	FOR row IN	
		select	s.*
		from	im_freelance_skills s
		where	s.user_id = p_user_id
		order by s.skill_type_id, s.skill_id
	LOOP
		IF '' != v_skills THEN v_skills := v_skills || ' '; END IF;
		v_skills := v_skills || '{' || 
			row.skill_type_id || ' ' || 
			row.skill_id || ' ' || 
			row.confirmed_experience_id || 
			'}';
	END LOOP;
	RETURN v_skills;
end;$body$ language 'plpgsql';
