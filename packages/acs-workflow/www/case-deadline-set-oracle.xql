<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="case_info">      
      <querytext>
      
    select case_id, 
           acs_object.name(object_id) as object_name, 
           state,
           workflow_key
    from   wf_cases
    where  case_id = :case_id

      </querytext>
</fullquery>

 
<fullquery name="a_week_from_now">      
      <querytext>
      select sysdate+7 from dual
      </querytext>
</fullquery>

 
</queryset>
