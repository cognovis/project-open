<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="unassigned_parties">      
      <querytext>
      
    select p.party_id,
           acs_object__name(p.party_id) as name,
           p.email
      from parties p,
           groups g
     where 
	   p.party_id = g.group_id
 	   and not exists (
		select 1 
		from wf_task_assignments ta 
		where ta.task_id = :task_id and ta.party_id = p.party_id
	   )
       and 0 < (select count(*)
                from   users u, party_approved_member_map m
                where  m.party_id = p.party_id
                and    u.user_id = m.member_id)


      </querytext>
</fullquery>

 
</queryset>
