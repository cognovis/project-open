<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="new_template">      
      <querytext>
      begin :1 := content_template.new(
         template_id => :template_id,
         name => :name,
         parent_id => :folder_id,
         creation_ip   => :creation_ip,
         creation_user => :creation_user
  ); end;
      </querytext>
</fullquery>

 
<fullquery name="get_path">      
      <querytext>

        select content_item.get_path(:folder_id) from dual

      </querytext>
</fullquery>


</queryset>
