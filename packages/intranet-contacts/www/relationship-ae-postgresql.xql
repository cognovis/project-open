<?xml version="1.0"?>
<queryset>

<fullquery name="get_rel_id">
      <querytext>
select rel_id
  from acs_rels
 where rel_type = :rel_type
   and ( object_id_one = :object_id_one and object_id_two = :object_id_two )
      </querytext>
</fullquery>

<fullquery name="rel_exists_p">
      <querytext>
select rel_id
  from acs_rels 
 where rel_type = :rel_type
   and object_id_one = :object_id_one
   and object_id_two = :object_id_two
      </querytext>
</fullquery>

<fullquery name="create_rel">
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

<fullquery name="insert_contact_rel">
      <querytext>
insert into contact_rels
       (rel_id)
values 
       (:rel_id)
      </querytext>
</fullquery>

</queryset>
