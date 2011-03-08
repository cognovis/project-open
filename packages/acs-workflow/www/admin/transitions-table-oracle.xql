<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="transtitions">      
      <querytext>
      
    select t.sort_order, 
           t.transition_key,
           t.transition_name,
           t.trigger_type,
           '' as trigger_type_pretty,
           t.role_key,
           r.role_name,
           '' as delete_url,
           '' as edit_url,
           '' as role_edit_url
      from wf_transitions t, wf_roles r
     where t.workflow_key = :workflow_key
       and r.workflow_key (+) = t.workflow_key
       and r.role_key (+) = t.role_key
     order by t.sort_order

      </querytext>
</fullquery>

 
</queryset>
