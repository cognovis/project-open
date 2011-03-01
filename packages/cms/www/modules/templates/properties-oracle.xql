<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_id">      
      <querytext>
      
    select 
      content_item.get_id(:path, content_template.get_root_folder) 
    from dual

      </querytext>
</fullquery>

<fullquery name="get_root_id">      
      <querytext>
      
        select content_template.get_root_folder from dual

      </querytext>
</fullquery>

<fullquery name="get_path">      
      <querytext>

      select content_item.get_path(:id) from dual

      </querytext>
</fullquery>

 
</queryset>
