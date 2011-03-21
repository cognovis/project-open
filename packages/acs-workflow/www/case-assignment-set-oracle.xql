<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="case_info">      
      <querytext>
      
    select case_id, 
           acs_object.name(object_id) as object_name, 
           state,
           workflow_key
    from   wf_cases
    where  case_id = :case_id

      </querytext>
</fullquery>

 
<fullquery name="party_with_at_least_one_member">      
      <querytext>
      
    select p.party_id,
           acs_object.name(p.party_id) as name, 
           case when p.email = '' then '' else '('||p.email||')' end as email
    from   parties p
    where  0 < (select count(*)
                from   users u, party_approved_member_map m
                where  m.party_id = p.party_id
                and    u.user_id = m.member_id)

      </querytext>
</fullquery>

 
</queryset>
