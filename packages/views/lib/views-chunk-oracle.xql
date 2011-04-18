<?xml version="1.0"?>
<queryset>
<rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="select_views">      
	<querytext>
	select t.* from
    	(
    	select o.object_id,
    	       acs_object.name(o.object_id) as object_name,
        	   p.first_names,
	           p.last_name,
    	       v.views_count as total_views,
        	   v.viewer_id as viewing_user_id,
	           v.last_viewed,
	           to_char(v.last_viewed, 'Mon DD, YYYY') as pretty_last_viewed
	    from (select * from acs_objects where object_type = :object_type
	    connect by prior object_id = context_id	 
	    start with object_id = :package_id) o, 
	         views_views v,
	         persons p
	    where v.object_id = o.object_id
	    and p.person_id = v.viewer_id
	    ) t
	where 1=1 $where_clause
	$orderby_clause
	</querytext>
</fullquery>

</queryset>