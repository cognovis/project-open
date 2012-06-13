<?xml version="1.0"?>
<queryset>

<fullquery name="get_other_party_ids">
      <querytext>
    select case when object_id_one = :party_id then object_id_two else object_id_one end as other_party_id
    from acs_rels
    where rel_id in ([join $rel_id ,])
      </querytext>
</fullquery>

<fullquery name="all_roles">
      <querytext>
    select distinct case when r.object_id_one = :party_id then t.role_two else t.role_one end as role_one,
           case when r.object_id_one = :party_id then t.role_one else t.role_two end as role_two,
           case when r.object_id_one = :party_id then 1 else 0 end as switch_roles_p
    from acs_rel_types t, acs_rels r
    where r.rel_type = t.rel_type
    and rel_id in ([join $rel_id ,])
      </querytext>
</fullquery>

</queryset>
