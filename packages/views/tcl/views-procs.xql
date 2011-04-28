<?xml version="1.0"?>
<queryset>

<fullquery name="views::get.views">      
	<querytext>
	select views_count, unique_views, to_char(last_viewed,'YYYY-MM-DD HH24:MI:SS') as last_viewed
    from view_aggregates
    where object_id = :object_id
	</querytext>
</fullquery>

<fullquery name="views::get.select_views_by_type">      
	<querytext>
	select view_type, views_count
    from view_aggregates_by_type
    where object_id = :object_id
</querytext>
</fullquery>

<fullquery name="views::viewed_p.get_viewed_p">      
	<querytext>
	select count(*)
    from views_views
    where object_id = :object_id
    and viewer_id = :user_id
	</querytext>
</fullquery>

<fullquery name="views::viewed_p.get_viewed_by_type_p">      
	<querytext>
	select count(*)
	from views_by_type
	where object_id = :object_id
	and viewer_id = :user_id
	and view_type = :type
	</querytext>
</fullquery>

</queryset>