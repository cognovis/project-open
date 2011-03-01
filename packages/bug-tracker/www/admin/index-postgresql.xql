<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="project_info">      
      <querytext>
       
    select p.maintainer,
           u.first_names as maintainer_first_names,
           u.last_name as maintainer_last_name,
           u.email as maintainer_email
    from   bt_projects p left outer join 
           cc_users u on (u.user_id = p.maintainer)
    where  p.project_id = :package_id

      </querytext>
</fullquery>
 
<fullquery name="versions">      
      <querytext>
      
    select v.version_id,
           v.version_name,
           v.description,
           v.anticipated_freeze_date,
           v.actual_freeze_date,
           v.anticipated_release_date,
           v.actual_release_date,
           v.maintainer,
           u.first_names as maintainer_first_names,
           u.last_name as maintainer_last_name,
           u.email as maintainer_email,
           v.supported_platforms,
           v.active_version_p,
           v.assignable_p
    from   bt_versions v left outer join 
           cc_users u on (u.user_id = v.maintainer)
    where  v.project_id = :package_id

      </querytext>
</fullquery>

<fullquery name="components">
  <querytext>
    select c.component_id,
           c.component_name,
           c.description,
           c.maintainer,
           u.first_names as maintainer_first_names,
           u.last_name as maintainer_last_name,
           u.email as maintainer_email,
           (select count(*) from bt_bugs where component_id = c.component_id) as num_bugs
    from   bt_components c left outer join 
           cc_users u on (u.user_id = c.maintainer)
    where  c.project_id = :package_id
    order  by upper(component_name)
  </querytext>
</fullquery>





 
</queryset>
