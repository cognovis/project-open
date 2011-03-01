<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="current_version">
  <querytext>
    select v.version_id,
           v.version_name,
           v.description,
           v.anticipated_freeze_date,
           v.actual_freeze_date,
           v.anticipated_release_date,
           v.maintainer,
           u.first_names as maintainer_first_names,
           u.last_name as maintainer_last_name,
           u.email as maintainer_email,
           v.supported_platforms,
           v.active_version_p,
           v.assignable_p,
           decode( v.assignable_p, 't', 'Yes', 'No' ) as assignable_p_pretty,
           (select count(*) 
            from   bt_bugs b 
            where  b.found_in_version = v.version_id 
               or  b.fix_for_version = v.version_id
               or  b.fixed_in_version = v.version_id) as num_bugs
    from   bt_versions v,
           cc_users u
    where  v.project_id = :package_id
    and    v.active_version_p = 't'
    and    v.actual_release_date is null
    and    v.maintainer = u.user_id (+)
  </querytext>
</fullquery>


<fullquery name="future_versions">
  <querytext>
    
    select v.version_id,
           v.version_name,
           v.description,
           v.anticipated_freeze_date,
           v.actual_freeze_date,
           v.anticipated_release_date,
           v.maintainer,
           u.first_names as maintainer_first_names,
           u.last_name as maintainer_last_name,
           u.email as maintainer_email,
           v.supported_platforms,
           v.active_version_p,
           v.assignable_p,
           decode( v.assignable_p, 't', 'Yes', 'No' ) as assignable_p_pretty,
           (select count(*) 
            from   bt_bugs b 
            where  b.found_in_version = v.version_id 
               or  b.fix_for_version = v.version_id
               or  b.fixed_in_version = v.version_id) as num_bugs
    from   bt_versions v,
           cc_users u
    where  v.project_id = :package_id
    and    v.actual_release_date is null
    and    v.active_version_p = 'f'
    and    v.maintainer = u.user_id (+)
    order by v.anticipated_release_date, version_name

  </querytext>
</fullquery>


<fullquery name="past_versions">
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
           v.assignable_p,
           decode( v.assignable_p, 't', 'Yes', 'No' ) as assignable_p_pretty,
           (select count(*) 
            from   bt_bugs b 
            where  b.found_in_version = v.version_id 
               or  b.fix_for_version = v.version_id
               or  b.fixed_in_version = v.version_id) as num_bugs
    from   bt_versions v,
           cc_users u
    where  v.project_id = :package_id
    and    v.actual_release_date is not null
    and    v.maintainer = u.user_id (+)
    order by v.actual_release_date, version_name
  </querytext>
</fullquery>
</queryset>
