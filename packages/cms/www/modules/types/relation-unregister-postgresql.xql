<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>


<fullquery name="unregister">      
      <querytext>

	 
          select content_type__${unregister_method} (
	      :content_type,
	      :target_type,
	      :relation_tag
          );
         

      </querytext>
</fullquery>

</queryset>
