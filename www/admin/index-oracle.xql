<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="project_info">      
      <querytext>
       
    select p.maintainer,
           u.first_names as maintainer_first_names,
           u.last_name as maintainer_last_name,
           u.email as maintainer_email
    from   bt_projects p,
           cc_users u
    where  p.project_id = :package_id
    and    p.maintainer = u.user_id (+)

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
    from   bt_versions v,
           cc_users u
    where  v.project_id = :package_id
    and    v.maintainer = u.user_id (+)

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
    from   bt_components c,
           cc_users u
    where  c.project_id = :package_id
    and    c.maintainer = u.user_id (+)
    order  by upper(component_name)
  </querytext>
</fullquery>


 
</queryset>
