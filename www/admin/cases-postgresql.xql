<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>
 
<fullquery name="cases_table">      
      <querytext>
      
    select c.case_id, 
           o.object_type,
           ot.pretty_name as object_type_pretty,
           acs_object__name(c.object_id) as object_name, 
           c.state,
           jeo.creation_date as started_date,
           to_char(jeo.creation_date, 'Mon fmDDfm, YYYY HH24:MI:SS') as started_date_pretty,
           now() - jeo.creation_date as age
    from   wf_cases c, 
           acs_objects o,
           acs_object_types ot,
           journal_entries je,
           acs_objects jeo
    where  c.workflow_key = '[db_quote $workflow_key]'
    and    o.object_id = c.object_id
    and    ot.object_type = o.object_type
    and    je.object_id = c.case_id
    and    je.action = 'case start'
    and    jeo.object_id = je.journal_id
    [ad_dimensional_sql $dimensional_list where and]
    [ad_order_by_from_sort_spec $orderby $table_def]

      </querytext>
</fullquery>
 

 
</queryset>
