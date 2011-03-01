<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="roles">      
      <querytext>
      
    select r.sort_order, 
           r.role_key,
           r.role_name,
           '' as delete_url,
           '' as edit_url,
           '' as move_up_url,
           '' as move_down_url,
           0 as role_no,
           t.transition_key,
           t.transition_name,
           '' as transition_edit_url
      from wf_roles r, wf_transitions t
     where r.workflow_key = :workflow_key
       and t.workflow_key (+) = r.workflow_key
       and t.role_key (+) = r.role_key
     order by r.sort_order, t.sort_order

      </querytext>
</fullquery>

 
</queryset>
