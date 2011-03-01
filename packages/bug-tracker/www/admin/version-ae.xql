<?xml version="1.0"?>
<queryset>

<fullquery name="check_exists">      
      <querytext>
       select 1 from bt_versions where version_id = :version_id 
      </querytext>
</fullquery>

 
<fullquery name="insert_row">      
      <querytext>
      
            insert into bt_versions (
                version_id, 
                project_id,
                version_name, 
                description, 
                anticipated_freeze_date, 
                anticipated_release_date, 
                actual_freeze_date, 
                actual_release_date, 
                maintainer, 
                supported_platforms, 
                assignable_p
            ) values (
                :version_id, 
                :package_id, 
                :version_name, 
                :description , 
                $anticipated_freeze_date, 
                $anticipated_release_date, 
                $actual_freeze_date, 
                $actual_release_date, 
                :maintainer, 
                :supported_platforms, 
                :assignable_p
            )
        
      </querytext>
</fullquery>

 
<fullquery name="update_row">      
      <querytext>
      
        update bt_versions
        set    version_id = :version_id, 
               project_id = :package_id, 
               version_name = :version_name, 
               description = :description, 
               anticipated_freeze_date = $anticipated_freeze_date,
               anticipated_release_date = $anticipated_release_date, 
               actual_freeze_date = $actual_freeze_date, 
               actual_release_date = $actual_release_date, 
               maintainer = :maintainer, 
               supported_platforms = :supported_platforms, 
               assignable_p = :assignable_p
        where  version_id = :version_id
    
      </querytext>
</fullquery>

<fullquery name="version_select">
  <querytext>
    select version_id, 
           version_name, 
           description, 
           to_char(anticipated_freeze_date, 'YYYY MM DD HH24 MI') as anticipated_freeze_date, 
           to_char(anticipated_release_date, 'YYYY MM DD HH24 MI') as anticipated_release_date, 
           to_char(actual_freeze_date, 'YYYY MM DD HH24 MI') as actual_freeze_date, 
           to_char(actual_release_date, 'YYYY MM DD HH24 MI') as actual_release_date, 
           maintainer, 
           supported_platforms, 
           assignable_p
    from   bt_versions
    where  version_id = :version_id
  </querytext>
</fullquery>

 
</queryset>
