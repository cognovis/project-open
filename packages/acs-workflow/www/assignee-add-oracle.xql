<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="unassigned_parties">      
      <querytext>
      
    select p.party_id,
           acs_object.name(p.party_id) as name,
           p.email
      from parties p
     where not exists (select 1 from wf_task_assignments ta where ta.task_id = :task_id and ta.party_id = p.party_id)
       and 0 < (select count(*)
                from   users u, party_approved_member_map m
                where  m.party_id = p.party_id
                and    u.user_id = m.member_id)


      </querytext>
</fullquery>

 
</queryset>
