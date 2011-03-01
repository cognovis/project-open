<?xml version="1.0"?>
<queryset>

<fullquery name="role_one_count">
      <querytext>
    select count(*) as role_one_count
    from acs_rels
    where ( object_id_one in ([join $party_ids ,]) or object_id_two in ([join $party_ids ,]) )
    and rel_type = :rel_type
      </querytext>
</fullquery>

<fullquery name="role_two_count">
      <querytext>
    select count(*) as role_two_count
    from acs_rels
    where ( object_id_one = :object_id_two or object_id_two = :object_id_two )
    and rel_type = :rel_type
      </querytext>
</fullquery>

</queryset>
