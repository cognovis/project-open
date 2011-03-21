<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="category_tree::map.map_tree">      
      <querytext>
	    select category_tree__map(
			      :object_id,
			      :tree_id,
			      :subtree_category_id,
			      :assign_single_p,
			      :require_category_p,
			      :widget
			      )
      </querytext>
</fullquery>

<fullquery name="category_tree::unmap.unmap_tree">      
      <querytext>
	    select category_tree__unmap(:object_id,:tree_id)
      </querytext>
</fullquery>

 
<fullquery name="category_tree::copy.copy_tree">      
      <querytext>
	    select category_tree__copy(:source_tree, :dest_tree, :creation_user, :creation_ip)
      </querytext>
</fullquery>

 
<fullquery name="category_tree::add.insert_tree">      
      <querytext>
        	select category_tree__new (
					 :tree_id,
					 :locale,
					 :name,
					 :description,
                                         :site_wide_p,
                                         current_timestamp,
					 :user_id,
					 :creation_ip,
					 :context_id
					 )
      </querytext>
</fullquery>

 
<fullquery name="category_tree::add.insert_default_tree">      
      <querytext>
		    select category_tree__new_translation (
						   :tree_id,
						   :default_locale,
						   :name,
						   :description,
                                                   current_timestamp,
						   :user_id,
						   :creation_ip
						   )
      </querytext>
</fullquery>

 
<fullquery name="category_tree::update.insert_tree_translation">      
      <querytext>
		    select category_tree__new_translation (
						   :tree_id,
						   :locale,
						   :name,
						   :description,
                                                   current_timestamp,
						   :user_id,
						   :modifying_ip
						   )
      </querytext>
</fullquery>

 
<fullquery name="category_tree::update.update_tree_translation">      
      <querytext>
		    select category_tree__edit (
					:tree_id,
					:locale,
					:name,
					:description,
                                        :site_wide_p,
                                        current_timestamp,
					:user_id,
					:modifying_ip
					)
      </querytext>
</fullquery>

 
<fullquery name="category_tree::delete.delete_tree">      
      <querytext>
        	    select category_tree__del ( :tree_id )
      </querytext>
</fullquery>

 
<fullquery name="category_tree::usage.category_tree_usage">      
      <querytext>
	    select t.pretty_plural, n.object_id, n.title, p.package_id,
	           p.instance_name,
	           acs_permission__permission_p(n.object_id, :user_id, 'read') as read_p
	    from category_tree_map m, acs_objects n,
	         apm_packages p, apm_package_types t
	    where m.tree_id = :tree_id
	    and n.object_id = m.object_id
	    and p.package_id = n.package_id
	    and t.package_key = p.package_key
      </querytext>
</fullquery>

 
</queryset>
