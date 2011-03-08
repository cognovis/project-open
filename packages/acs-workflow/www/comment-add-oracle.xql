<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="case">      
      <querytext>
      
    select case_id,
           acs_object.name(object_id) as object_name,
           state
    from   wf_cases
    where  case_id = :case_id

      </querytext>
</fullquery>

 
</queryset>
