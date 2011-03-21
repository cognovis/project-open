<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

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
      (select o.object_id 
         from (select tree_ancestor_keys(acs_objects_get_tree_sortkey(:object_id)) as tree_sortkey) parents,
           acs_objects o
        where o.tree_sortkey = parents.tree_sortkey
          and tree_level(o.tree_sortkey) >= (select
                                                case when max(tree_level(ob.tree_sortkey)) is null
                                                  then 0
                                                  else max(tree_level(ob.tree_sortkey))
                                                end  
                                              from
                                                (select tree_ancestor_keys(acs_objects_get_tree_sortkey(:object_id))
                                                  as tree_sortkey) parents,
                                                acs_objects ob
                                              where ob.tree_sortkey = parents.tree_sortkey
                                                and ob.security_inherit_p = 'f')) o
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
  ) tmp 
  order by
    grantee_name, privilege
  
      </querytext>
</fullquery>

 
</queryset>
