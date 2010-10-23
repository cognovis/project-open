<?xml version="1.0"?>
<queryset>

<fullquery name="category::relation::add_meta_category.get_meta_relation_id">
    <querytext>
        select 
		rel_id
        from   
		acs_rels 
        where  
		rel_type = 'meta_category_rel'
        	and object_id_one = :category_id_one
        	and object_id_two = :category_id_two
    </querytext>
</fullquery>

<fullquery name="category::relation::add_meta_category.get_user_meta_relation_id">
    <querytext>
        select 
		rel_id
        from   
		acs_rels 
        where  
		rel_type = 'user_meta_category_rel'
        	and object_id_one = :meta_category_id
        	and object_id_two = :user_id
    </querytext>
</fullquery>

<fullquery name="category::relation::get_meta_category_internal.get_categories">
    <querytext>
 	select object_id_one, object_id_two
	from acs_rels
	where rel_id = :rel_id
	and rel_type = 'meta_category_rel'
    </querytext>
</fullquery>


</queryset>