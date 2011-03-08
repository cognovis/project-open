<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="workflow_reject">      
      <querytext>


        select content_workflow__reject(
                             :task_id,
                             :user_id,
                             :ip_address,
                             :transition_key,
                             :msg
                         );
                       
      </querytext>
</fullquery>

 
<fullquery name="get_status">      
      <querytext>
      
  select content_workflow__can_reject( :task_id, :user_id ) 

      </querytext>
</fullquery>

 
<fullquery name="get_task_info">      
      <querytext>
      
  select
    c.object_id, content_item__get_title(c.object_id,'f') as title, 
    tr.transition_name
  from
    wf_tasks tk, wf_cases c,
    wf_transitions tr
  where
    tk.task_id = :task_id
  and
    tk.transition_key = tr.transition_key
  and
    tk.workflow_key = tr.workflow_key
  and
    tk.workflow_key = 'publishing_wf'
  and
    tk.case_id = c.case_id
  and
    content_workflow__can_reject( tk.task_id, :user_id ) = 't'

      </querytext>
</fullquery>

 
<fullquery name="get_rejects">      
      <querytext>
      
  select
    trans.transition_name, trans.transition_key
  from
    wf_places src, wf_places dest, wf_tasks t, wf_transitions trans
  where
    src.workflow_key = dest.workflow_key
  and
    src.workflow_key = 'publishing_wf'
  and
    src.workflow_key = trans.workflow_key
  and
    src.place_key = content_workflow__get_this_place( t.transition_key )
  and
    -- for the publishing_wf, past transitions have a lower sort order
    dest.sort_order < src.sort_order
  and
    -- get the transition associated with that place
    content_workflow__get_this_place( trans.transition_key ) = dest.place_key
  and
    t.task_id = :task_id
  order by
    dest.sort_order desc

      </querytext>
</fullquery>


<fullquery name="is_valid_task">      
      <querytext>

             select content_workflow__can_reject( :task_id, :user_id ) from dual

      </querytext>
</fullquery>

 
</queryset>
