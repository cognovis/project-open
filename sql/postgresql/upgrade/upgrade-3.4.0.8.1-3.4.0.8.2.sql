-- upgrade-3.4.0.8.1-3.4.0.8.2.sql

SELECT acs_log__debug('/packages/intranet-hr/sql/postgresql/upgrade/upgrade-3.4.0.8.1-3.4.0.8.2.sql','');

drop view im_employees_active;

create or replace view im_employees_active as
select
        u.*,
        e.*,
        pa.*,
        pe.*
from
        users u,
        parties pa,
        persons pe,
        im_employees e,
        groups g,
        group_distinct_member_map gdmm,
        cc_users cc
where
        u.user_id = pa.party_id
        and u.user_id = pe.person_id
        and u.user_id = e.employee_id
        and g.group_name = 'Employees'
        and gdmm.group_id = g.group_id
        and gdmm.member_id = u.user_id
        and (cc.object_id = u.user_id and cc.member_state = 'approved');
