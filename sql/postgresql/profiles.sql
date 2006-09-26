





select  *
from
        (select DISTINCT
                g.group_name,
                g.group_id,
                p.profile_gif,
                'group' as object_type
        from
                acs_objects o,
                groups g,
                im_profiles p
        where
                g.group_id = o.object_id
                and g.group_id = p.profile_id
                and o.object_type = 'im_profile'
                and g.group_name not in (
                        'Customers', 'Freelancers', 'Freelance Managers', 'HR Managers', 'P/O Admins'
                )
    UNION
        select DISTINCT
                p.first_names || ' ' || p.last_name as group_name,
                p.person_id as group_id,
                '' as profile_gif,
                'person' as object_type
        from
                persons p,
                acs_permissions_all apa,
                im_cost_centers cc
        where
                p.person_id = apa.grantee_id
                and apa.object_id = cc.cost_center_id
                and p.person_id not in (
                        select  member_id
                        from    group_approved_member_map
                        where   group_id = [im_admin_group_id]
                )
        ) g
order by
        object_type,
        group_name
