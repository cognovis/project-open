<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="category::add.insert_category">      
      <querytext>
		select category__new (
				    :category_id,
				    :tree_id,
				    :locale,
				    :name,
				    :description,
				    :parent_id,
                                    :deprecated_p,
                                    current_timestamp,
				    :user_id,
				    :creation_ip
				    )
      </querytext>
</fullquery>

 
<fullquery name="category::add.insert_default_category">      
      <querytext>
		    select category__new_translation (
					      :category_id,
					      :default_locale,
					      :name,
					      :description,
                                              current_timestamp,
					      :user_id,
					      :creation_ip
					      )
      </querytext>
</fullquery>

 
<fullquery name="category::update.insert_category_translation">      
      <querytext>
		    select category__new_translation (
					      :category_id,
					      :locale,
					      :name,
					      :description,
                                              current_timestamp,
					      :user_id,
					      :modifying_ip
					      )
      </querytext>
</fullquery>

 
<fullquery name="category::update.update_category_translation">      
      <querytext>
		    select category__edit (
				   :category_id,
				   :locale,
				   :name,
				   :description,
                                   current_timestamp,
				   :user_id,
				   :modifying_ip
				   )
      </querytext>
</fullquery>

 
<fullquery name="category::delete.delete_category">      
      <querytext>
	    select category__del ( :category_id )
      </querytext>
</fullquery>

 
<fullquery name="category::change_parent.change_parent_category">      
      <querytext>
	    select category__change_parent (
				    :category_id,
				    :tree_id,
				    :parent_id
				    )
      </querytext>
</fullquery>

 
<fullquery name="category::phase_in.phase_in">      
      <querytext>
	    select category__phase_in(:category_id)
      </querytext>
</fullquery>

 
<fullquery name="category::phase_out.phase_out">      
      <querytext>
	    select category__phase_out(:category_id)
      </querytext>
</fullquery>

 
<fullquery name="category::get_object_context.object_name">      
      <querytext>
            select acs_object__name(:object_id) 
      </querytext>
</fullquery>

 
</queryset>
