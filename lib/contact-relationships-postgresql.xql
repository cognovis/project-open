<?xml version="1.0"?>
<queryset>

<fullquery name="get_relationships">
      <querytext>
select rel_id, other_party_id, role, role_singular, rel_type, creation_date
  from ( select object_id_two as other_party_id,
                role_two as role,
                pretty_name as role_singular,
                acs_rels.rel_id, acs_rels.rel_type
           from acs_rels, 
                acs_rel_types,
		acs_rel_roles
          where acs_rels.rel_type = acs_rel_types.rel_type
            and object_id_one = :party_id
	    and acs_rel_types.role_two = acs_rel_roles.role
            and acs_rels.rel_type in ( select object_type from acs_object_types where supertype in ('contact_rel','im_biz_object_member'))
	 union 
	 select object_id_one as other_party_id,
                role_one as role,
                pretty_name as role_singular,
                acs_rels.rel_id, acs_rels.rel_type
           from acs_rels, 
                acs_rel_types,
		acs_rel_roles
          where acs_rels.rel_type = acs_rel_types.rel_type
            and object_id_two = :party_id
	    and acs_rel_types.role_one = acs_rel_roles.role
            and acs_rels.rel_type in ( select object_type from acs_object_types where supertype in ('contact_rel','im_biz_object_member'))
       ) rels_temp, acs_objects
where rels_temp.rel_id = acs_objects.object_id
      </querytext>
</fullquery>

</queryset>
