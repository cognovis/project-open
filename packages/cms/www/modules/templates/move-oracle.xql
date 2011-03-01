<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="move_item">      
      <querytext>
      begin 
        content_item.move(
          :template_id, :folder_id
        );
      end;
      </querytext>
</fullquery>

 
<fullquery name="get_path">      
      <querytext>
      select content_item.get_path(:folder_id) from dual
      </querytext>
</fullquery>

 
</queryset>
