<?xml version="1.0"?>

<queryset>

<fullquery name="get_employees">
    <querytext>
	select
		r.object_id_one as emp_id
	from
		acs_rels r
	where
		r.object_id_two = :customer_id
		and rel_type = 'contact_rels_employment'
    </querytext>
</fullquery>

<fullquery name="get_users">
    <querytext>
	select
		user_id,
		first_names ||' '|| last_name as fullname
	from
		cc_users
	order by
		last_name asc
    </querytext>
</fullquery>

<fullquery name="get_groups">
    <querytext>
	select
		group_id,
		group_name
	from
		groups
	order by
		group_name asc
    </querytext>
</fullquery>

<fullquery name="get_projects">
    <querytext>
	select
		item_id as project_item_id
	from
		cr_items	
	where
		content_type = 'pm_project'
    </querytext>
</fullquery>

<fullquery name="get_revision_info">
    <querytext>
	select 
		cct.*, 
		cr.title, 
		cr.description 
	from 
		contact_complaint_track cct, 
		cr_revisions cr 
	where 
		complaint_id = :complaint_id 
		and revision_id = :complaint_id	
    </querytext>
</fullquery>

</queryset>