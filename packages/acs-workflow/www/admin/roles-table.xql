<?xml version="1.0"?>
<queryset>

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
      from wf_roles r left outer join wf_transitions t on (t.workflow_key = r.workflow_key and t.role_key = r.role_key)
     where r.workflow_key = :workflow_key
     order by r.sort_order, t.sort_order

      </querytext>
</fullquery>

 
</queryset>
