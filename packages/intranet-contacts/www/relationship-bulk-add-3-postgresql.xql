<?xml version="1.0"?>
<queryset>

<fullquery name="delete_all_rels">
      <querytext>
select acs_object__delete(rel_id)
  from acs_rels
 where ( object_id_one = :party_id or object_id_two = :party_id )
   and rel_type = :rel_type
      </querytext>
</fullquery>

<fullquery name="rel_exists_p">
      <querytext>
select rel_id
  from acs_rels 
 where rel_type = :rel_type
   and ((:switch_roles_p = 0 and object_id_one = :object_id_one and object_id_two = :object_id_two)
   or (:switch_roles_p = 1 and object_id_one = :object_id_two and object_id_two = :object_id_one))
      </querytext>
</fullquery>

<fullquery name="create_forward_rel">
      <querytext>
select acs_rel__new (
                     :rel_id,
                     :rel_type,
                     :object_id_one,
                     :object_id_two,
                     :context_id,
                     :creation_user,
                     :creation_ip  
                    )
      </querytext>
</fullquery>

<fullquery name="create_backward_rel">
      <querytext>
select acs_rel__new (
                     :rel_id,
                     :rel_type,
                     :object_id_two,
                     :object_id_one,
                     :context_id,
                     :creation_user,
                     :creation_ip  
                    )
      </querytext>
</fullquery>

<fullquery name="insert_contact_rel">
      <querytext>
insert into contact_rels
       (rel_id)
values 
       (:rel_id)
      </querytext>
</fullquery>

</queryset>
