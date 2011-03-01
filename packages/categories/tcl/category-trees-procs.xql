<?xml version="1.0"?>
<queryset>

<fullquery name="category_tree::get_data.get_tree_data">      
      <querytext>
      
	    select site_wide_p
	    from category_trees
	    where tree_id = :tree_id
	
      </querytext>
</fullquery>

<fullquery name="category_tree::get_categories.get_categories">
       <querytext>
            select c.category_id as category_id from categories c, category_translations ct
            where parent_id is null
		and tree_id = :tree_id
		and c.category_id = ct.category_id
		and locale = :locale
            order by name
       </querytext>
</fullquery>
         
<fullquery name="category_tree::edit_mapping.edit_mapping">
      <querytext>
      
	    update category_tree_map
	    set assign_single_p = :assign_single_p,
                require_category_p = :require_category_p,
                widget = :widget
	    where tree_id = :tree_id
	    and object_id = :object_id
	
      </querytext>
</fullquery>

<fullquery name="category_tree::get_id.get_category_tree_id">
      <querytext>
      
		select tree_id
		from category_tree_translations
		where name = :name
		and locale = :locale
	    
      </querytext>
</fullquery>

<fullquery name="category_tree::get_id_by_object_title.get_tree_id">
      <querytext>

                select object_id
                from acs_objects
                where title = :title
                and object_type = 'category_tree'

      </querytext>
</fullquery>
 
<fullquery name="category_tree::update.check_tree_existence">      
      <querytext>
      
		select 1
		from category_tree_translations
		where tree_id = :tree_id
		and locale = :locale
	    
      </querytext>
</fullquery>

 
<fullquery name="category_tree::get_mapped_trees.get_mapped_trees">      
      <querytext>
      
	    select tree_id, subtree_category_id, assign_single_p,
	           require_category_p, widget
	    from category_tree_map
	    where object_id = :object_id
	
      </querytext>
</fullquery>
<fullquery name="category_tree::get_trees.get_trees">      
      <querytext>
      
	    select distinct tree_id
	    from category_object_map_tree
	    where object_id = :object_id
	
      </querytext>
</fullquery>

<fullquery name="category_tree::get_mapped_trees_from_object_list.get_mapped_trees_from_object_list">      
      <querytext>
      
            select tree_id, subtree_category_id, assign_single_p,
                   require_category_p, widget
            from category_tree_map
            where object_id in ([join $object_id_list ", "])
        
      </querytext>
</fullquery>

 
<fullquery name="category_tree::reset_cache.reset_cache">      
      <querytext>
      
	    select tree_id, category_id, left_ind, right_ind,
	           case when deprecated_p = 'f' then '' else '1' end as deprecated_p
	    from categories
	    order by tree_id, left_ind
	
      </querytext>
</fullquery>

 
<fullquery name="category_tree::flush_cache.flush_cache">      
      <querytext>
      
	    select category_id, left_ind, right_ind,
	           case when deprecated_p = 'f' then '' else '1' end as deprecated_p
	    from categories
	    where tree_id = :tree_id
	    order by left_ind
	
      </querytext>
</fullquery>

 
<fullquery name="category_tree::reset_translation_cache.reset_translation_cache">      
      <querytext>
      
	    select tree_id, locale, name, description
	    from category_tree_translations
	    order by tree_id, locale
	
      </querytext>
</fullquery>

 
<fullquery name="category_tree::flush_translation_cache.flush_translation_cache">      
      <querytext>
      
	    select locale, name, description
	    from category_tree_translations
	    where tree_id = :tree_id
	    order by locale
	
      </querytext>
</fullquery>

 
<fullquery name="category_tree::get_id.get_category_tree_id">
      <querytext>
      
		select tree_id
		from category_tree_translations
		where name = :name
		and locale = :locale
	    
      </querytext>
</fullquery>


</queryset>
