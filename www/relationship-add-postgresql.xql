<?xml version="1.0"?>
<queryset>

<fullquery name="role_exists_p">
      <querytext>
select 1
  from contact_rel_types
 where primary_role = :role
 limit 1
      </querytext>
</fullquery>

<fullquery name="get_secondary_role_pretty">
      <querytext>
select acs_rel_type__role_pretty_name(:role_two) as secondary_role_pretty
      </querytext>
</fullquery>

<fullquery name="get_rel_types">
      <querytext>
select rel_type,
       primary_role,
       acs_rel_type__role_pretty_name(primary_role) as primary_role_pretty
  from contact_rel_types
 where secondary_role = :role_two
   and secondary_object_type in (:contact_type_two,'party')
   and primary_object_type in (:contact_type_one,'party')
      </querytext>
</fullquery>

<fullquery name="get_roles">
      <querytext>
select role_one as db_role_one,
       role_two as db_role_two
  from acs_rel_types
 where rel_type = :rel_type
      </querytext>
</fullquery>

</queryset>
