<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="category_link::add.insert_category_link">
      <querytext>
        	select category_link__new (
					 :from_category_id,
					 :to_category_id
					 )
      </querytext>
</fullquery>

 
<fullquery name="category_link::delete.delete_category_link">
      <querytext>
        	    select category_link__del ( :link_id )
      </querytext>
</fullquery>

 
</queryset>
