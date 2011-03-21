<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="category::add.insert_category">      
      <querytext>
      
		begin
		:1 := category.new (
				    category_id   => :category_id,
				    locale        => :locale,
				    name          => :name,
				    description   => :description,
				    tree_id       => :tree_id,
				    parent_id     => :parent_id,
				    creation_user => :user_id,
				    creation_ip   => :creation_ip
				    );
		end;
	    
      </querytext>
</fullquery>

 
<fullquery name="category::add.insert_default_category">      
      <querytext>
      
		    begin
		    category.new_translation (
					      category_id    => :category_id,
					      locale         => :default_locale,
					      name           => :name,
					      description    => :description,
					      modifying_user => :user_id,
					      modifying_ip   => :creation_ip
					      );
		    end;
		
      </querytext>
</fullquery>

 
<fullquery name="category::update.insert_category_translation">      
      <querytext>
      
		    begin
		    category.new_translation (
					      category_id    => :category_id,
					      locale         => :locale,
					      name           => :name,
					      description    => :description,
					      modifying_user => :user_id,
					      modifying_ip   => :modifying_ip
					      );
		    end;
		
      </querytext>
</fullquery>

 
<fullquery name="category::update.update_category_translation">      
      <querytext>
      
		    begin
		    category.edit (
				   category_id    => :category_id,
				   locale         => :locale,
				   name           => :name,
				   description    => :description,
				   modifying_user => :user_id,
				   modifying_ip   => :modifying_ip
				   );
		    end;
		
      </querytext>
</fullquery>

 
<fullquery name="category::delete.delete_category">      
      <querytext>
      
	    begin
	    category.del ( :category_id );
	    end;
	
      </querytext>
</fullquery>

 
<fullquery name="category::change_parent.change_parent_category">      
      <querytext>
      
	    begin
	    category.change_parent (
				    category_id  => :category_id,
				    tree_id      => :tree_id,
				    parent_id    => :parent_id
				    );
	    end;
	
      </querytext>
</fullquery>

 
<fullquery name="category::phase_in.phase_in">      
      <querytext>
      
	    begin
	    category.phase_in(:category_id);
	    end;
	
      </querytext>
</fullquery>

 
<fullquery name="category::phase_out.phase_out">      
      <querytext>
      
	    begin
	    category.phase_out(:category_id);
	    end;
	
      </querytext>
</fullquery>

 
<fullquery name="category::get_object_context.object_name">      
      <querytext>
      select acs_object.name(:object_id) from dual
      </querytext>
</fullquery>

<fullquery name="category::map_object.insert_mapped_categories">      
      <querytext>
      
			insert into category_object_map (category_id, object_id)
			select :category_id, :object_id from dual
                        where not exists (select 1
                                          from category_object_map
                                          where category_id = :category_id
                                            and object_id = :object_id)
      </querytext>
</fullquery>
 
</queryset>
