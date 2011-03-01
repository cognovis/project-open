<?xml version="1.0"?>
<queryset>

<fullquery name="get_projects">
    <querytext>
	select 
		item_id 
	from 
		pm_projectsx 
	where 
		customer_id = :party_id 
    </querytext>
</fullquery>

<fullquery name="get_members">
    <querytext>
	select
		distinct
		pa.party_id as supplier_id
	from
		pm_project_assignment pa
	where
		pa.project_id in ([template::util::tcl_to_sql_list $project_list])
		and pa.party_id in ([template::util::tcl_to_sql_list $group_members_list])
    </querytext>
</fullquery>

</queryset>