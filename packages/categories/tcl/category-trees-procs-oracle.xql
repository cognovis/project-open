<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="category_tree::map.map_tree">      
      <querytext>
      
	    begin
	    category_tree.map(
			      object_id           => :object_id,
			      subtree_category_id => :subtree_category_id,
			      tree_id             => :tree_id,
			      assign_single_p     => :assign_single_p,
			      require_category_p  => :require_category_p,
			      widget              => :widget);
	    end;
	
      </querytext>
</fullquery>

 
<fullquery name="category_tree::unmap.unmap_tree">      
      <querytext>
      
	    begin
	    category_tree.unmap(
				object_id => :object_id,
				tree_id   => :tree_id);
	    end;
	
      </querytext>
</fullquery>

 
<fullquery name="category_tree::copy.copy_tree">      
      <querytext>
      
	    begin
	    category_tree.copy(
			       source_tree         => :source_tree,
			       dest_tree           => :dest_tree
			       );
	    end;
	
      </querytext>
</fullquery>

 
<fullquery name="category_tree::add.insert_tree">      
      <querytext>
      
		begin
		:1 := category_tree.new (
					 tree_id       => :tree_id,
					 tree_name     => :name,
					 description   => :description,
					 locale        => :locale,
					 creation_user => :user_id,
					 creation_ip   => :creation_ip,
					 context_id    => :context_id
					 );
		end;
	    
      </querytext>
</fullquery>

 
<fullquery name="category_tree::add.insert_default_tree">      
      <querytext>
      
		    begin
		    category_tree.new_translation (
						   tree_id        => :tree_id,
						   tree_name      => :name,
						   description    => :description,
						   locale         => :default_locale,
						   modifying_user => :user_id,
						   modifying_ip   => :creation_ip
						   );
		    end;
		
      </querytext>
</fullquery>

 
<fullquery name="category_tree::update.insert_tree_translation">      
      <querytext>
      
		    begin
		    category_tree.new_translation (
						   tree_id        => :tree_id,
						   tree_name      => :name,
						   description    => :description,
						   locale         => :locale,
						   modifying_user => :user_id,
						   modifying_ip   => :modifying_ip
						   );
		    end;
		
      </querytext>
</fullquery>

 
<fullquery name="category_tree::update.update_tree_translation">      
      <querytext>
      
		    begin
		    category_tree.edit (
					tree_id        => :tree_id,
					tree_name      => :name,
					description    => :description,
					locale         => :locale,
					modifying_user => :user_id,
					modifying_ip   => :modifying_ip
					);
		    end;
		
      </querytext>
</fullquery>

 
<fullquery name="category_tree::delete.delete_tree">      
      <querytext>
      
	    begin
	    category_tree.del ( :tree_id );
	    end;
	
      </querytext>
</fullquery>

 
<fullquery name="category_tree::usage.category_tree_usage">      
      <querytext>
      
	    select t.pretty_plural, n.object_id, n.title, p.package_id,
	           p.instance_name,
	           acs_permission.permission_p(n.object_id, :user_id, 'read') as read_p
	    from category_tree_map m, acs_objects n,
	         apm_packages p, apm_package_types t
	    where m.tree_id = :tree_id
	    and n.object_id = m.object_id
	    and p.package_id = n.package_id
	    and t.package_key = p.package_key
	
      </querytext>
</fullquery>

 
</queryset>
