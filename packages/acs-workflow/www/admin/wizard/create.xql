<?xml version="1.0"?>
<queryset>

<fullquery name="object_pretty_names">      
      <querytext>
      select pretty_name from acs_object_types
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
                      references wf_cases on delete cascade
)
      </querytext>
</fullquery>

 
<fullquery name="drop_cases_table">      
      <querytext>
      drop table $workflow_cases_table
      </querytext>
</fullquery>

 
</queryset>
