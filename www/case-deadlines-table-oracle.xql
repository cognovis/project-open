<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="deadlines">      
      <querytext>
      
    select tr.transition_name, 
           tr.transition_key, 
           to_char(cd.deadline, :date_format) as deadline_pretty,
           '' as edit_url,
           '' as remove_url
    from   (select c.case_id, tr.sort_order, tr.transition_name, tr.transition_key, tr.workflow_key from wf_cases c, wf_transitions tr
            where c.case_id = :case_id and c.workflow_key = tr.workflow_key) tr,
            wf_case_deadlines cd
    where  tr.case_id = cd.case_id(+)
    and    tr.transition_key = cd.transition_key(+)
    and    tr.workflow_key = cd.workflow_key(+)
    order by tr.sort_order

      </querytext>
</fullquery>

 
</queryset>
