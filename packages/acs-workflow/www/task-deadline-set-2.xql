<?xml version="1.0"?>
<queryset>

<fullquery name="deadline_update">      
      <querytext>
      
update wf_tasks set deadline = :deadline_date
where task_id = :task_id
      </querytext>
</fullquery>

 
</queryset>
