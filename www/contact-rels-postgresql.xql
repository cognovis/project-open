<?xml version="1.0"?>
<queryset>

<fullquery name="get_valid_object_types">
      <querytext>
select primary_object_type
  from contact_rel_types
 where primary_role = :role_two 
       and secondary_object_type = :contact_type
      </querytext>
</fullquery>

<fullquery name="get_rels">
      <querytext>
select acs_rel_type__role_pretty_name(primary_role) as pretty_name,
       primary_role as role
  from contact_rel_types
 where secondary_object_type in ( :contact_type, 'party' )
 group by primary_role
 order by upper(acs_rel_type__role_pretty_name(primary_role))
      </querytext>
</fullquery>

<fullquery name="get_relationships">
      <querytext>
select rel_id, im_name_from_id(other_party_id) as other_name, other_party_id, role_singular, rel_type
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
                        ) rels_temp
[template::list::orderby_clause -orderby -name "relationships"]
      </querytext>
</fullquery>

<fullquery name="contacts_select">      
      <querytext>
select $object_deref as name,object_id from acs_objects where object_type = :role_two_type and $object_deref is not null and lower($object_deref) like lower('%$query%')
 order by upper($object_deref)
 limit 100
      </querytext>
</fullquery>


</queryset>
