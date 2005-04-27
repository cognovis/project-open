<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="case_info">      
      <querytext>
      
    select case_id, 
           acs_object__name(object_id) as object_name, 
           state,
           workflow_key
    from   wf_cases
    where  case_id = :case_id

      </querytext>
</fullquery>

 
</queryset>
