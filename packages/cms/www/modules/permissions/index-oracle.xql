<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_permissions">      
      <querytext>
      
  select * from ( 
    select 
      p.pretty_name, 
      p.privilege, 
      u.party_id as grantee_id,
      n.first_names || ' ' || n.last_name as grantee_name,
      u.email
    from 
      acs_permissions per, acs_privileges p, parties u,
      persons n,
      (select object_id from acs_objects 
	 connect by prior context_id = object_id 
		and prior security_inherit_p = 't'
	 start with object_id = :object_id) o
    where
      per.privilege = p.privilege
    and
      per.grantee_id = u.party_id
    and
      per.object_id = o.object_id
    and
      u.party_id = n.person_id
  union
    select
      p.pretty_name, p.privilege, 
      -1 as grantee_id, 'All Users' as grantee_name, '&nbsp;' as email 
    from
      acs_permissions per, acs_privileges p, parties u
    where
      u.party_id = -1
    and
      per.object_id = :object_id
    and
      per.privilege = p.privilege
    and
      per.grantee_id = u.party_id
  ) order by
    grantee_name, privilege
  
      </querytext>
</fullquery>

 
</queryset>
