<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="panels">      
      <querytext>
      
    select t.transition_key,
           t.transition_name,
           '' as transition_edit_url,
           '' as panel_add_url,
           pan.sort_order,
           0 as panel_no,
           pan.header,
           pan.template_url,
           pan.template_url as template_url_pretty,
           pan.overrides_action_p,
           pan.only_display_when_started_p,
           0 as rowspan,
           '' as panel_edit_url,
           '' as panel_delete_url
      from wf_transitions t, wf_context_task_panels pan
     where t.workflow_key = :workflow_key
       and pan.workflow_key (+) = t.workflow_key
       and pan.context_key (+) = :context_key
       and pan.transition_key (+) = t.transition_key
     order by t.sort_order, pan.sort_order

      </querytext>
</fullquery>

 
</queryset>
