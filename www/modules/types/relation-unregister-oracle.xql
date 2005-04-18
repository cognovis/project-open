<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>


<fullquery name="unregister">      
      <querytext>

	  begin
          content_type.${unregister_method} (
	      $content_key => :content_type,
	      $target_key  => :target_type,
	      relation_tag => :relation_tag
          );
          end;

      </querytext>
</fullquery>

</queryset>
