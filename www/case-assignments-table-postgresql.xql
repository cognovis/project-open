<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="manual_assignments">      
      <querytext>

    select p.party_id,
           acs_object__name(p.party_id) as name,
           p.email,
           '' as url,
           '' as remove_url,
           '' as edit_url,
           o.object_type,
           r.role_key,
           r.role_name
      from wf_cases c, 
	   ((wf_roles r LEFT OUTER JOIN wf_case_assignments ca
	     ON (r.role_key = ca.role_key and ca.case_id = :case_id)) LEFT OUTER JOIN parties p 
	       ON (ca.party_id = p.party_id)) LEFT OUTER JOIN acs_objects o
	         ON (p.party_id =  o.object_id)
     where c.case_id = :case_id
       and r.workflow_key = c.workflow_key
     order by r.sort_order, r.role_key, name

      </querytext>
</fullquery>

 
</queryset>
