<?xml version="1.0"?>
<queryset>

<fullquery name="num_object_types">      
      <querytext>
       
	    select case when count(*) = 0 then 0 else 1 end from acs_object_types where pretty_name = :workflow_name 
	
      </querytext>
</fullquery>

 
<fullquery name="object_types">      
      <querytext>
      select object_type from acs_object_types
      </querytext>
</fullquery>

 
<fullquery name="constraints">      
      <querytext>
      select constraint_name from user_constraints
      </querytext>
</fullquery>

 
<fullquery name="create_cases_table">      
      <querytext>
      
    create table $workflow_cases_table (
    case_id             integer primary key
                        constraint $workflow_cases_constraint
                        references wf_cases
    )
      </querytext>
</fullquery>

 
<fullquery name="start_place">      
      <querytext>
      
        insert into wf_places (place_key, workflow_key, place_name, sort_order)
        values ('start', :workflow_key, 'Start place', 1)
    
      </querytext>
</fullquery>

 
<fullquery name="end_place">      
      <querytext>
      
        insert into wf_places (place_key, workflow_key, place_name, sort_order)
        values ('end', :workflow_key, 'End place', 999)
    
      </querytext>
</fullquery>

 
<fullquery name="drop_cases_table">      
      <querytext>
      drop table $workflow_cases_table
      </querytext>
</fullquery>

 
</queryset>
