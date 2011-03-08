<?xml version="1.0"?>
<queryset>

<fullquery name="get_rel_info">
      <querytext>
select *
  from acs_rels
 where ( object_id_one = :party_id or object_id_two = :party_id )
   and rel_id = :rel_id
      </querytext>
</fullquery>

<fullquery name="delete_rel">
      <querytext>
select acs_object__delete($rel_id)  from dual
      </querytext>
</fullquery>

</queryset>
