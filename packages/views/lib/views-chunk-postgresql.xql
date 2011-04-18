<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="select_views">      
	<querytext>
	select t.* from
    	(
	    select o.object_id,
    	       acs_object__name(o.object_id) as object_name,
        	   p.first_names,
	           p.last_name,
    	       v.views_count as total_views,
        	   v.viewer_id as viewing_user_id,
	           v.last_viewed,
	           to_char(v.last_viewed, 'Mon DD, YYYY') as pretty_last_viewed
	    from acs_objects o, 
	    	 acs_objects b, 
	         views_views v,
	         persons p
	    where o.object_type = :object_type
			  and o.tree_sortkey between b.tree_sortkey and tree_right(b.tree_sortkey)
			  and b.object_id = :package_id
	          and v.object_id = o.object_id
	          and p.person_id = v.viewer_id
	    ) t
	    where true $where_clause
	    $orderby_clause
	        
	</querytext>
</fullquery>

</queryset>