<?xml version="1.0"?>
<queryset>

<fullquery name="get_saved_extend_ids">
    <querytext>
	select
		ceo.extend_id
	from
		contact_search_extend_map cse,
		contact_extend_options ceo
	where 
		cse.search_id = :search_id
		and ceo.extend_id = cse.extend_id
		and ceo.aggregated_p = 't'
    </querytext>
</fullquery>

<fullquery name="check">
    <querytext>
	select 
		1
	from
		contact_search_extend_map
	where
		search_id = :search_id
		and extend_id = :extend
    </querytext>
</fullquery>

<fullquery name="insert_extend">
    <querytext>
	insert into contact_search_extend_map (search_id, extend_id, attribute_id)
	values (:search_id, :extend, null)
    </querytext>
</fullquery>

<fullquery name="update_search">
    <querytext>
	update contact_searches set aggregated_attribute = :aggregate_attribute_id 
	where search_id = :search_id
    </querytext>
</fullquery>

<fullquery name="get_attribute_options">
    <querytext>
	select 
                ot.option_id,
		ot.option 
	from 
		ams_option_types ot
	where 
		ot.attribute_id = :attr_id
    </querytext>
</fullquery>

<fullquery name="get_countries_options">
    <querytext>
	select 
	        c.default_name as option,
		c.iso
	from 
		countries c
    </querytext>
</fullquery>

<fullquery name="get_value_id">
    <querytext>
	select 
		value_id 
	from
		ams_options 
	where 
		option_id = :option_id
    </querytext>
</fullquery>

<fullquery name="get_results">
    <querytext>
    select 
         count(parties.party_id)
    from 
         parties
    where parties.party_id in (
          select 	
		parties.party_id
	  from 
                parties
                left join organizations on (parties.party_id = organizations.organization_id)
                left join cr_items on (parties.party_id = cr_items.item_id)
                left join cr_revisions on (cr_items.latest_revision = cr_revisions.revision_id ), 
                group_distinct_member_map
                where parties.party_id = group_distinct_member_map.member_id
                $search_clause
          ) 
          and parties.party_id in (
          select
               distinct
               p.party_id
          from
              ams_attribute_values a,
              cr_items i,
              parties p
          where
              a.object_id = i.latest_revision and
              i.item_id = p.party_id
              and a.value_id = $value_id )
    </querytext>
</fullquery>


<fullquery name="get_countries_results">
    <querytext>
    select 
         count(parties.party_id)
    from 
         parties
    where parties.party_id in (
          select 	
		parties.party_id
	  from 
                parties
                left join organizations on (parties.party_id = organizations.organization_id)
                left join cr_items on (parties.party_id = cr_items.item_id)
                left join cr_revisions on (cr_items.latest_revision = cr_revisions.revision_id ), 
                group_distinct_member_map
                where parties.party_id = group_distinct_member_map.member_id
                $search_clause
          ) 
          and parties.party_id in (
			select	
			       	p.party_id
			from
			       	parties p,
				ams_attribute_values a,
				postal_addresses pa,
				cr_items i,
				cr_revisions r
			where
				i.item_id = p.party_id
				and r.revision_id = i.latest_revision
				and r.revision_id = a.object_id
				and a.value_id = pa.address_id
				and pa.country_code = :iso
			)
    </querytext>
</fullquery>

<fullquery name="get_relationship_options">
    <querytext>
	select
		distinct
		ot.pretty_name as option,
		rt.rel_type
	from
		acs_rel_types rt,
		acs_object_types ot,
		parties p
	where	
		rt.rel_type like 'contact_rels_%'
		and rt.rel_type = ot.object_type
    </querytext>
</fullquery>

<fullquery name="get_relationship_results">
    <querytext>
    	select 
		count(t.party_id)
    	from 
		(
		select	
			distinct
		        CASE WHEN r.object_id_one = parties.party_id 
			THEN r.object_id_one
			ELSE r.object_id_two END as party_id
		from
			acs_rels r
		where
			r.rel_type = :rel_type
		) t,
		cr_items ci,
		cr_revisions cr
	where 
		t.party_id =  ci.item_id
		and ci.latest_revision = cr.revision_id
		$search_clause
    </querytext>
</fullquery>

<fullquery name="get_extend_options">
    <querytext>
	select
    		ceo.pretty_name,
    		ceo.extend_id as e_id
   	from 
		contact_extend_options ceo
    	where 
    		ceo.aggregated_p = 't'
		and ceo.extend_id not in ( 
			select 
				extend_id 
			from 
				contact_search_extend_map 
			where 
				search_id = :search_id
		)
    </querytext>
</fullquery>

<fullquery name="get_extend_results">
    <querytext>
	$extend_subquery
	and party_id in (
          select 	
		parties.party_id
	  from 
                parties
                left join organizations on (parties.party_id = organizations.organization_id)
                left join cr_items on (parties.party_id = cr_items.item_id)
                left join cr_revisions on (cr_items.latest_revision = cr_revisions.revision_id ), 
                group_distinct_member_map
                where parties.party_id = group_distinct_member_map.member_id
                $search_clause
          ) 
          and parties.party_id in (
          select
               distinct
               p.party_id
          from
              ams_attribute_values a,
              cr_items i,
              parties p
          where
              a.object_id = i.latest_revision and
              i.item_id = p.party_id
              and a.value_id = $value_id )
    </querytext>
</fullquery>

<fullquery name="get_countries_extend_results">
    <querytext>
	$extend_subquery
    	and party_id in (
          select 	
		parties.party_id
	  from 
                parties
                left join organizations on (parties.party_id = organizations.organization_id)
                left join cr_items on (parties.party_id = cr_items.item_id)
                left join cr_revisions on (cr_items.latest_revision = cr_revisions.revision_id ), 
                group_distinct_member_map
                where parties.party_id = group_distinct_member_map.member_id
                $search_clause
          ) 
          and parties.party_id in (
			select	
			       	p.party_id
			from
			       	parties p,
				ams_attribute_values a,
				postal_addresses pa,
				cr_items i,
				cr_revisions r
			where
				i.item_id = p.party_id
				and r.revision_id = i.latest_revision
				and r.revision_id = a.object_id
				and a.value_id = pa.address_id
				and pa.country_code = :iso
			)
    </querytext>
</fullquery>

<fullquery name="get_relationship_extend_results">
    <querytext>
	$extend_subquery
	and party_id in (
    	select 
		t.party_id
    	from 
		(
		select	
			distinct
		        CASE WHEN r.object_id_one = parties.party_id 
			THEN r.object_id_one
			ELSE r.object_id_two END as party_id
		from
			acs_rels r
		where
			r.rel_type = :rel_type
		) t,
		cr_items ci,
		cr_revisions cr
	where 
		t.party_id =  ci.item_id
		and ci.latest_revision = cr.revision_id
		$search_clause )
    </querytext>
</fullquery>

</queryset>
