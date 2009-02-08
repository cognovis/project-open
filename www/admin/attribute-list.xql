<?xml version="1.0"?>
<queryset>

<fullquery name="get_search_for">
    <querytext>
        select
                object_type
        from
                contact_searches
        where
                search_id = :search_id
    </querytext>
</fullquery>

<fullquery name="get_var_list">
    <querytext>
        select
                var_list
        from
                contact_search_conditions
        where
                type = 'group'
                and search_id = :search_id
    </querytext>
</fullquery>


<fullquery name="get_ams_options">
    <querytext>
        select
		distinct
                lam.attribute_id,
		a.pretty_name,
		a.attribute_name
        from
                ams_list_attribute_map lam,
                ams_lists l,
		ams_attributes a
        where
                lam.list_id = l.list_id
		and lam.attribute_id = a.attribute_id
                [template::list::page_where_clause -and -name "ams_options" -key "lam.attribute_id"]
		$extend_query
                $search_for_clause
                [template::list::orderby_clause -name "ams_options" -orderby]
    </querytext>
</fullquery>

<fullquery name="get_ams_options_pagination">
    <querytext>
        select
		distinct
                lam.attribute_id,
		a.pretty_name,
		a.attribute_name	
        from
                ams_list_attribute_map lam,
                ams_lists l,
		ams_attributes a
        where
                lam.list_id = l.list_id
		and lam.attribute_id = a.attribute_id
		$extend_query
                $search_for_clause
                [template::list::orderby_clause -name "ams_options" -orderby]
    </querytext>
</fullquery>

<fullquery name="get_default_p">
    <querytext>
	select
		1
	from 
		contact_search_extend_map
	where
		search_id = :search_id
		and attribute_id = :attribute_id
    </querytext>
</fullquery>


</queryset>