<?xml version="1.0"?>
<queryset>
<fullquery name="category::count_children.select">
        <querytext>
             select count(*)
             from categories
             where parent_id=:category_id
        </querytext>
</fullquery>


<fullquery name="category::get_children.get_children_ids">
      <querytext>

		select category_id
		from categories
		where parent_id = :category_id
        and deprecated_p = 'f'
        order by tree_id, left_ind

      </querytext>
</fullquery>

<fullquery name="category::get_parent.get_parent_id">
      <querytext>

		select parent_id
		from categories
		where category_id = :category_id

      </querytext>
</fullquery>

<fullquery name="category::get_id.get_category_id">      
      <querytext>
      
		select category_id
		from category_translations
		where name = :name
		and locale = :locale
	    
      </querytext>
</fullquery>

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
			select :category_id, :object_id
                        where not exists (select 1
                                          from category_object_map
                                          where category_id = :category_id
                                            and object_id = :object_id);
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

<fullquery name="category::get_mapped_categories_multirow.select">      
      <querytext>
      
	    select co.tree_id, aot.title, c.category_id, ao.title
	    from category_object_map_tree co, categories c, category_translations ct, acs_objects ao, acs_objects aot
	    where co.object_id = :object_id
		and co.category_id = c.category_id
		and c.category_id = ao.object_id
		and c.category_id = ct.category_id
		and aot.object_id = co.tree_id
		and ct.locale = :locale
	    order by aot.title, ao.title
	
      </querytext>
</fullquery>

<fullquery name="category::get_mapped_categories.get_filtered">
        <querytext>
                SELECT category_object_map.category_id
                FROM category_object_map, categories
                WHERE object_id = :object_id 
                  AND tree_id = :tree_id
                  AND category_object_map.category_id = categories.category_id
        </querytext>
</fullquery>

<fullquery name="category::get_objects.get_objects">
        <querytext>
                SELECT com.object_id
                FROM category_object_map com $join_clause
                WHERE com.category_id = :category_id $where_clause
        </querytext>
</fullquery>

<fullquery name="category::get_id_by_object_title.get_category_id">
      <querytext>

                select object_id
                from acs_objects
                where title = :title
                and object_type = 'category'

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
