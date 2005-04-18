<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_id">      
      <querytext>
      
    select 
      content_item__get_id(:path, content_template__get_root_folder(), 'f')    

      </querytext>
</fullquery>

<fullquery name="get_root_id">      
      <querytext>
      
        select content_template__get_root_folder()

      </querytext>
</fullquery>

<fullquery name="get_path">      
      <querytext>

      select content_item__get_path(:id, null)

      </querytext>
</fullquery>

 
</queryset>
