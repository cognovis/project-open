<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="manual_assignments">      
      <querytext>
      
    select p.party_id,
           acs_object.name(p.party_id) as name,
           p.email,
           '' as url,
           '' as remove_url,
           '' as edit_url,
           o.object_type,
           r.role_key,
           r.role_name
      from wf_cases c, wf_roles r, wf_case_assignments ca, parties p, acs_objects o
     where c.case_id = :case_id
       and r.workflow_key = c.workflow_key
       and ca.case_id (+) = :case_id
       and ca.role_key (+) = r.role_key 
       and p.party_id (+) = ca.party_id 
       and o.object_id (+) = p.party_id 
     order by r.sort_order, r.role_key, name

      </querytext>
</fullquery>

 
</queryset>
