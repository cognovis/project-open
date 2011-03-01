<?xml version="1.0"?>
<queryset>

<fullquery name="project_maintainer_update">      
      <querytext>
      
        update bt_projects
        set    maintainer = :maintainer
        where  project_id = :package_id
    
      </querytext>
</fullquery>

 
</queryset>
