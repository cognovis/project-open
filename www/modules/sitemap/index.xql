<?xml version="1.0"?>
<queryset>

<fullquery name="get_module_name">      
      <querytext>
      
    select name from cm_modules where key = :mount_point
  
      </querytext>
</fullquery>

 
<fullquery name="get_reg_types">      
      <querytext>
      
    select
      content_type
    from
      cr_folder_type_map
    where
      folder_id = :root_id
  
      </querytext>
</fullquery>


 
<fullquery name="get_types">      
      <querytext>
      
    select
      content_type
    from
      cr_folder_type_map
    where
      folder_id = :id
  
      </querytext>
</fullquery>

 
</queryset>
