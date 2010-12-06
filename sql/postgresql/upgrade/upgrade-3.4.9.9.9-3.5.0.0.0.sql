-- upgrade-3.4.9.9.9-3.5.0.0.0.sql

SELECT acs_log__debug('/packages/intranet-hr/sql/postgresql/upgrade/upgrade-3.4.9.9.9-3.5.0.0.0.sql','');


drop view im_employees_active;

create or replace view im_employees_active as
select
        u.*,
        e.*,
        pa.*,
        pe.*
from
        users u,
        group_distinct_member_map gdmm,
        parties pa,
        persons pe
        LEFT OUTER JOIN im_employees e ON (pe.person_id = e.employee_id)
where
        u.user_id = pa.party_id and
        u.user_id = pe.person_id and
        u.user_id = e.employee_id and
        u.user_id = gdmm.member_id and
        gdmm.group_id in (select group_id from groups where group_name = 'Employees') and
        u.user_id in (
                select  r.object_id_two
                from    acs_rels r,
                        membership_rels mr
                where   r.rel_id = mr.rel_id and
                        r.object_id_one in (
                                select group_id
                                from groups
                                where group_name = 'Registered Users'
                        ) and mr.member_state = 'approved'
        )
;

