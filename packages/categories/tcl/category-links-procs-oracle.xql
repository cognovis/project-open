<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="category_link::add.insert_category_link">
      <querytext>
      
		begin
		:1 := category_link.new (
					 from_category_id => :from_category_id,
					 to_category_id   => :to_category_id
					);
		end;
	    
      </querytext>
</fullquery>

 
<fullquery name="category_link::delete.delete_category_link">
      <querytext>
      
	    begin
	    category_link.del ( :link_id );
	    end;
	
      </querytext>
</fullquery>

 
</queryset>
