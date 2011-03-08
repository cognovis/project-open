<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="move_item">      
      <querytext>


        select content_item__move(
          :template_id, :folder_id
        );
     
      </querytext>
</fullquery>

 
<fullquery name="get_path">      
      <querytext>
      select content_item__get_path(:folder_id, null) 
      </querytext>
</fullquery>

 
</queryset>
