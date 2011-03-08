<?xml version="1.0"?>
<queryset>

<fullquery name="select_searches">
    <querytext>
	select 
		cs.search_id, 
		CASE
		WHEN cs.title is not null
		THEN cs.title
		ELSE 'Search \#'||to_char(search_id,'FM9999999999999999999')||' on '||to_char(creation_date,'Mon FMDD') 
		END as title,
		CASE
		WHEN cs.title is not null
		THEN upper(cs.title)
		ELSE 
		upper('Search \#'||to_char(search_id,'FM9999999999999999999')||' on '||to_char(creation_date,'Mon FMDD'))
		END as order_title,
		cs.all_or_any, 
		cs.object_type,
		cs.owner_id as search_owner_id
      	from 
		contact_searches cs,
		acs_objects o
      	where 
	      	not cs.deleted_p
		and o.object_id = cs.search_id
          	[template::list::page_where_clause -and -name "searches" -key "cs.search_id"]
	     	[template::list::orderby_clause -name "searches" -orderby]	
      </querytext>
</fullquery>

<fullquery name="select_searches_pagination">
    <querytext>
	select 
		cs.search_id,
		CASE
		WHEN cs.title is not null
		THEN upper(cs.title)
		ELSE 
		upper('Search \#'||to_char(search_id,'FM9999999999999999999')||' on '||to_char(creation_date,'Mon FMDD'))
		END as order_title
      	from 
		contact_searches cs,
		acs_objects o
      	where 
	      	not cs.deleted_p
		and o.object_id = cs.search_id
	     	[template::list::orderby_clause -name "searches" -orderby]	
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
		and aggreagated_attribute is not null
    </querytext>
</fullquery>

</queryset>
