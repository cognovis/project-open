<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="case_info">      
      <querytext>
      
    select case_id, 
           acs_object__name(object_id) as object_name, 
           state,
           workflow_key
    from   wf_cases
    where  case_id = :case_id

      </querytext>
</fullquery>

 
<fullquery name="party_with_at_least_one_member">      
      <querytext>

select * from (      
    select p.party_id,
           acs_object__name(p.party_id) as name, 
           case when p.email = '' then '' else '('||p.email||')' end as email
    from   parties p
    where  0 < (select count(*)
                from   users u, party_approved_member_map m
                where  m.party_id = p.party_id
                and    u.user_id = m.member_id)
) t order by name, email

      </querytext>
</fullquery>

 
</queryset>
