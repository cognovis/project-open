<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="rename_folder">      
      <querytext>
      
    begin 
    content_folder.edit_name (
        folder_id   => :item_id, 
        name        => :name, 
        label       => :label, 
        description => :description
    ); 
    end;
      </querytext>
</fullquery>

 
</queryset>
