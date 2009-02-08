<?xml version="1.0"?>
<queryset>

<fullquery name="get_valid_object_types">
      <querytext>
select primary_object_type
  from contact_rel_types
 where primary_role = :role_two 
      </querytext>
</fullquery>

<fullquery name="get_rels">
      <querytext>
select acs_rel_type__role_pretty_name(primary_role) as pretty_name,
       primary_role as role
  from contact_rel_types
 where secondary_object_type in ([template::util::tcl_to_sql_list $object_types])
 group by primary_role
 order by upper(acs_rel_type__role_pretty_name(primary_role))
      </querytext>
</fullquery>

<fullquery name="get_rel_info">
      <querytext>
select *
  from contact_rel_types
 where primary_role = :role_one
   and secondary_role = :role_two
   and primary_object_type in ([template::util::tcl_to_sql_list $object_types])
      </querytext>
</fullquery>

<fullquery name="get_secondary_object_type">
      <querytext>
select secondary_role
  from contact_rel_types
 where primary_role = :role_one
   and secondary_role = :role_two
   and primary_object_type in ([template::util::tcl_to_sql_list $object_types])
      </querytext>
</fullquery>

<fullquery name="get_role_one_pretty">
      <querytext>
select acs_rel_type__role_pretty_name(:role_one)
      </querytext>
</fullquery>

<fullquery name="get_rel_types">
      <querytext>
select acs_rel_type__role_pretty_name(primary_role),
       primary_role
  from contact_rel_types
 where secondary_role = :role_two
   and primary_object_type in ([template::util::tcl_to_sql_list $object_types])
      </querytext>
</fullquery>

<fullquery name="get_role_one">
      <querytext>
select role_one
  from acs_rel_types
 where rel_type = :rel_type
      </querytext>
</fullquery>

<fullquery name="delete_rel">
      <querytext>
select acs_object__delete(rel_id)
  from acs_rels
 where (
         ( object_id_one = :object_id_one and object_id_two = :object_id_two )
       ) or (
         ( object_id_one = :object_id_two and object_id_two = :object_id_one )
       )
   and rel_type = :rel_type
      </querytext>
</fullquery>

</queryset>
