<?xml version="1.0"?>
<queryset>

<fullquery name="project_info_update">      
      <querytext>
      
            update bt_projects
            set    description = :description,
                   email_subject_name = :email_subject_name,
                   maintainer = :maintainer
            where  project_id = :package_id
        
      </querytext>
</fullquery>

<fullquery name="project_select">
  <querytext>
        select pa.instance_name as name,
               pr.description, 
               pr.email_subject_name,
               pr.maintainer
        from   bt_projects pr,
               apm_packages pa
        where  pr.project_id = :package_id
        and    pa.package_id = pr.project_id
  </querytext>
</fullquery>

 
</queryset>
