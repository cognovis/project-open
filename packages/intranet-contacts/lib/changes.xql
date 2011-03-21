<?xml version="1.0"?>
<queryset>

<fullquery name="get_changes">
    <querytext>	
	select
		cp.revision_id,
		to_char(cp.publish_date, 'YYYY-MM-DD HH24:MI:SS') as publish_date,
		im_name_from_user_id(cu.user_id) as name,
		i.live_revision
	from 
		contact_party_revisionsx cp,
		cc_users cu,
		cr_items i
	where 
		cp.item_id = :party_id
		and cu.user_id = cp.creation_user
		and i.item_id = cp.item_id
		order by revision_id desc
    </querytext>
</fullquery>

</queryset>