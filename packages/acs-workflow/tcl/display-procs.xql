<?xml version="1.0"?>
<queryset>

<fullquery name="wf_assignment_widget.assignment_select">      
      <querytext>
      
	    select ca.party_id
	      from wf_case_assignments ca, wf_cases c
	     where c.case_id = :case_id
	       and ca.role_key = :role_key
	       and ca.workflow_key = c.workflow_key
	
      </querytext>
</fullquery>

 
</queryset>
