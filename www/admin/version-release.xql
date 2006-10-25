<?xml version="1.0"?>
<queryset>

<fullquery name="update_version">      
      <querytext>
      
        update bt_versions
        set    actual_release_date = $actual_release_date
        where  version_id = :version_id
    
      </querytext>
</fullquery>

 
</queryset>
