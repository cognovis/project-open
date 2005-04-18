<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_path">      
      <querytext>

        select content_item.get_path(:parent_id) from dual

      </querytext>
</fullquery>


<fullquery name="new_folder">      
      <querytext>

   begin :1 := content_folder.new(
         folder_id => :folder_id,
         name => :name,
         label => :label,
         description => :description,
         parent_id => :parent_id,
         creation_ip   => :creation_ip,
         creation_user => :creation_user
  ); end;
       </querytext>
</fullquery>
 
</queryset>
