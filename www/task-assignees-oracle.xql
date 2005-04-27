<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="assignees">      
      <querytext>
      
    select p.party_id,
           acs_object.name(p.party_id) as name,
           p.email,
           '' as remove_url,
           o.object_type
    from   wf_task_assignments ta,
           parties p,
           acs_objects o
    where  ta.task_id = :task_id
    and    p.party_id = ta.party_id
    and    o.object_id = p.party_id

      </querytext>
</fullquery>

 
<fullquery name="effective_assignees">      
      <querytext>
      
    select distinct u.user_id,
           acs_object.name(u.user_id) as name,
           p.email,
           '/shared/community-member?user_id=' || u.user_id as url
    from   wf_task_assignments ta,
           party_approved_member_map m,
           parties p,
           users u
    where  ta.task_id = :task_id
    and    m.party_id = ta.party_id
    and    p.party_id = m.member_id
    and    u.user_id = p.party_id

      </querytext>
</fullquery>

 
</queryset>
