<?xml version="1.0"?>

<queryset>

<fullquery name="get_complaints">
    <querytext>
	select 
		cct.*, cr.title, cr.description
	from
		contact_complaint_track cct, cr_items ci, cr_revisions cr
	where
		ci.latest_revision = cct.complaint_id
	        and cr.revision_id = cct.complaint_id
		[template::list::filter_where_clauses -and -name complaint] 
    </querytext>
</fullquery>

<fullquery name="get_users">
    <querytext>
	select 
		distinct cct.customer_id as c_id, 
		cct.supplier_id as s_id,
		( select im_name_from_user_id(user_id) from cc_users where user_id = customer_id) as customer,
		( select im_name_from_user_id(user_id) from cc_users where user_id = supplier_id) as supplier
	from
		contact_complaint_track cct
    </querytext>
</fullquery>

<fullquery name="get_revision_info">
    <querytext>
	select 
		title, 
		description 
	from
		cr_revisions 
	where 
		revision_id = :complaint_id	
    </querytext>
</fullquery>

</queryset>