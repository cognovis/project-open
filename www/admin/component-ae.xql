<?xml version="1.0"?>
<queryset>

<fullquery name="component_create">      
      <querytext>
      
        insert into bt_components
        (component_id, project_id, component_name, description, url_name, maintainer)
        values
        (:component_id, :package_id, :name, :description, :url_name, :maintainer)
    
      </querytext>
</fullquery>

 
<fullquery name="component_update">      
      <querytext>
      
        update bt_components
        set    component_name = :name,
               description = :description,
               maintainer = :maintainer,
               url_name = :url_name
        where  component_id = :component_id
    
      </querytext>
</fullquery>

 
</queryset>
