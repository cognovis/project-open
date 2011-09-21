-- upgrade-3.4.1.0.7-3.4.1.0.8.sql

SELECT acs_log__debug('/packages/intranet-hr/sql/postgresql/upgrade/upgrade-3.4.1.0.7-3.4.1.0.8.sql','');




create or replace function inline_0 ()
returns integer as $body$
declare
        v_count         integer;
begin

	select count(*) into v_count from pg_class
	where relname = 'im_employees_active';
        IF v_count = 0 THEN return 1; END IF;

	DROP VIEW im_employees_active; 
        RETURN 0;

end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




create or replace view im_employees_active as
select
	u.*,
	e.*,
	pa.*,
	pe.*
from
	users u,
	parties pa,
	persons pe
	LEFT OUTER JOIN im_employees e ON (pe.person_id = e.employee_id)
where
	u.user_id = pa.party_id and
	u.user_id = pe.person_id and
	u.user_id = e.employee_id and
	u.user_id in (
		select	gdmm.member_id
		from	group_distinct_member_map gdmm
		where	group_id in (select group_id from groups where group_name = 'Employees')
	) and
	u.user_id in (
		select	r.object_id_two
		from	acs_rels r,
			membership_rels mr
		where	r.rel_id = mr.rel_id and
			r.object_id_one in (
				select group_id 
				from groups 
				where group_name = 'Registered Users'
			) and mr.member_state = 'approved'
	)
;
