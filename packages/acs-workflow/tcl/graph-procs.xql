<?xml version="1.0"?>
<queryset>

<fullquery name="wf_get_workflow_net_internal.workflow_name">      
      <querytext>
       select pretty_name from acs_object_types where object_type = :workflow_key 
      </querytext>
</fullquery>

 
<fullquery name="wf_get_workflow_net_internal.transition_def">      
      <querytext>
      
	select transition_key,
	       transition_name,
	       sort_order,
	       trigger_type
	from   wf_transitions
	where  workflow_key = :workflow_key
	order  by sort_order
    
      </querytext>
</fullquery>

 
<fullquery name="wf_get_workflow_net_internal.places_def">      
      <querytext>
      
	select p.place_key,
	       p.place_name,
	       p.sort_order
	from   wf_places p
	where  p.workflow_key = :workflow_key
	order  by p.sort_order
    
      </querytext>
</fullquery>

 
<fullquery name="wf_get_workflow_net_internal.arcs_def">      
      <querytext>
      
	select transition_key,
	       place_key,
	       direction,
	       guard_callback,
	       guard_custom_arg,
	       guard_description
	from   wf_arcs
	where  workflow_key = :workflow_key
    
      </querytext>
</fullquery>

 
<fullquery name="wf_generate_dot_representation.package_id">      
      <querytext>
      select package_id from apm_packages where package_key='acs-workflow'
      </querytext>
</fullquery>

 
<fullquery name="wf_generate_dot_representation.package_id">      
      <querytext>
      select package_id from apm_packages where package_key='acs-workflow'
      </querytext>
</fullquery>

 
<fullquery name="wf_generate_dot_representation.package_id">      
      <querytext>
      select package_id from apm_packages where package_key='acs-workflow'
      </querytext>
</fullquery>

 
</queryset>
