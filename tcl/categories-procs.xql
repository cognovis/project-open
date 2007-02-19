<?xml version="1.0"?>
<queryset>

<fullquery name="category::update.check_category_existence">      
      <querytext>
      
		select 1
		from category_translations
		where category_id = :category_id
		and locale = :locale
	    
      </querytext>
</fullquery>

 
<fullquery name="category::map_object.remove_mapped_categories">      
      <querytext>
      
		    delete from category_object_map
		    where object_id = :object_id
		
      </querytext>
</fullquery>

 
<fullquery name="category::map_object.insert_mapped_categories">      
      <querytext>
      
			insert into category_object_map (category_id, object_id)
			values (:category_id, :object_id)
		    
      </querytext>
</fullquery>

 
<fullquery name="category::map_object.insert_linked_categories">      
      <querytext>
      
			insert into category_object_map (category_id, object_id)
			(select l.to_category_id as category_id, m.object_id
			from category_links l, category_object_map m
			where l.from_category_id = m.category_id
			and m.object_id = :object_id
			and not exists (select 1
					from category_object_map m2
					where m2.object_id = :object_id
					and m2.category_id = l.to_category_id))
		    
      </querytext>
</fullquery>

 
<fullquery name="category::get_mapped_categories.get_mapped_categories">      
      <querytext>
      
	    select category_id
	    from category_object_map
	    where object_id = :object_id
	
      </querytext>
</fullquery>

 
<fullquery name="category::reset_translation_cache.reset_translation_cache">      
      <querytext>
      
	    select t.category_id, c.tree_id, t.locale, t.name
	    from category_translations t, categories c
	    where t.category_id = c.category_id
	    order by t.category_id, t.locale
	
      </querytext>
</fullquery>

 
<fullquery name="category::flush_translation_cache.flush_translation_cache">      
      <querytext>
      
	    select t.locale, t.name, c.tree_id
	    from category_translations t, categories c
	    where t.category_id = :category_id
	    and t.category_id = c.category_id
	    order by t.locale
	
      </querytext>
</fullquery>

 
<fullquery name="category::pageurl.get_tree_id_for_pageurl">      
      <querytext>
      
	    select tree_id
	    from categories
	    where category_id = :object_id
	
      </querytext>
</fullquery>

 
</queryset>
