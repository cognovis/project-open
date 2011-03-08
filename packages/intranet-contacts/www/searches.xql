<?xml version="1.0"?>
<queryset>

<fullquery name="select_owner_options">
      <querytext>
      select CASE WHEN owner_id = :user_id
                  THEN '\#intranet-contacts.My_Searches\#'
                  ELSE contact__name(owner_id) END,
             owner_id
        from ( select distinct cs.owner_id
                 from contact_searches cs, acs_objects ao
                where cs.search_id = ao.object_id
                  and ( ao.title is not null or cs.owner_id = :user_id )
                  and cs.owner_id in ( select party_id from parties )) distinct_owners
        order by CASE WHEN owner_id = :user_id THEN '0000000000000000000' ELSE upper(contact__name(owner_id)) END
      </querytext>
</fullquery>

<fullquery name="select_searches">
      <querytext>
(    select cs.search_id,
            ao.title,
            upper(ao.title) as order_title,
            cs.all_or_any,
            cs.object_type
       from contact_searches cs, acs_objects ao
      where cs.search_id = ao.object_id
        and cs.owner_id = :owner_id
        and ao.title is not null
        and not cs.deleted_p
) union (
     select cs.search_id,
            'Search \#' || to_char(cs.search_id,'FM999999999999') || ' on ' || to_char(ao.creation_date,'Mon FMDD') as title,
            'zzzzzzzzzzz' || replace( to_char(999999999999 - cs.search_id,'999999999999') , ' ' , '0') as order_title,
	    cs.all_or_any,
            cs.object_type
       from contact_searches cs, acs_objects ao
      where cs.owner_id = :owner_id
        and cs.search_id = ao.object_id
        and ao.title is null
        and not cs.deleted_p
      limit 10
)
      order by order_title
      </querytext>
</fullquery>

<fullquery name="get_saved_p">
    <querytext>
	select
		aggregated_attribute
	from
		contact_searches
	where
		search_id = :search_id
		and aggregated_attribute is not null
    </querytext>
</fullquery>

</queryset>
