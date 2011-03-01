<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="bug_tracker::bug_notify.bug">      
      <querytext>
      
        select b.bug_id,
               b.bug_number,
               b.summary,
               b.project_id,
               o.creation_user as submitter_user_id,
               submitter.first_names as submitter_first_names,
               submitter.last_name as submitter_last_name,
               submitter.email as submitter_email,
               b.component_id,
               c.component_name,
               o.creation_date,
               to_char(o.creation_date, 'fmMM/DDfm/YYYY') as creation_date_pretty,
               st.pretty_name as status,
               b.resolution,
               b.user_agent,
               b.found_in_version,
               b.fix_for_version,
               b.fixed_in_version,
               to_char(now(), 'fmMon/DDfm/YYYY') as now_pretty
        from   bt_bugs b,
               acs_objects o,
               bt_components c,
               cc_users submitter,
               workflow_cases cas,
               workflow_case_fsm cfsm,
               workflow_fsm_states st
        where  b.bug_id = :bug_id
        and    b.project_id = :package_id
        and    o.object_id = b.bug_id
        and    c.component_id = b.component_id
        and    submitter.user_id = o.creation_user
        and    cas.object_id = b.bug_id
        and    cfsm.case_id = cas.case_id
        and    cfsm.current_state = st.state_id
    
      </querytext>
</fullquery>

 
<fullquery name="bug_tracker::get_project_info_internal.project_info">      
      <querytext>
      
        select pck.instance_name as project_name,
               prj.description as project_description,
               prj.folder_id as project_folder_id,
               prj.root_keyword_id as project_root_keyword_id,
               ver.version_id as current_version_id,
               coalesce(ver.version_name, 'None') as current_version_name
        from   apm_packages pck, 
               bt_projects prj 
               left outer join bt_versions ver 
               on (ver.project_id = prj.project_id and active_version_p = 't')
        where  pck.package_id = :package_id 
        and    prj.project_id = pck.package_id
    
      </querytext>
</fullquery>
 
<fullquery name="bug_tracker::bugs_exist_p_not_cached.select_bugs_exist_p">      
      <querytext>
        select 1 
        from  bt_bugs 
        where project_id = :package_id 
        limit 1
      </querytext>
</fullquery>

<fullquery name="bug_tracker::get_user_prefs_internal.user_info">      
      <querytext>
      
        select u.first_names as user_first_names, 
               u.last_name as user_last_name,
               u.email as user_email,
               ver.version_id as user_version_id,
               coalesce(ver.version_name, 'None') as user_version_name
        from   cc_users u,
               bt_user_prefs up
               left outer join bt_versions ver
               on (ver.version_id = up.user_version)
        where  u.user_id = :user_id
        and    up.user_id = u.user_id
        and    up.project_id = :package_id
    
      </querytext>
</fullquery>
 
 
<fullquery name="bug_tracker::delete_all_project_keywords.keywords_delete">      
      <querytext>
        select bt_project__keywords_delete(:package_id, 'f')
      </querytext>
</fullquery>

  <fullquery name="bug_tracker::parse_filters.assignee_name">      
      <querytext>
       select acs_object__name(party_id) from parties where party_id = :filter_assignee 
      </querytext>
  </fullquery>

  <partialquery name="bug_tracker::parse_filters.n_days_filter">      
      <querytext>
        age(b.creation_date) < interval '$filter_n_days days'
      </querytext>
  </partialquery>

  <partialquery name="bug_tracker::parse_filters.keyword_filter">
      <querytext>
        content_keyword__is_assigned(b.bug_id, $keyword_id, 'none')
      </querytext>
  </partialquery>

  <partialquery name="bug_tracker::parse_filters.orderby_filter_from_bug">
      <querytext>
         left outer join cr_item_keyword_map km_order on (km_order.item_id = b.bug_id) 
         join cr_keywords kw_order on (km_order.keyword_id = kw_order.keyword_id and kw_order.parent_id = :filter_orderby)
      </querytext>
  </partialquery>
 
  <partialquery name="bug_tracker::parse_filters.orderby_filter_where">
      <querytext>
          1=1
      </querytext>
  </partialquery>
 
  <fullquery name="bug_tracker::project_delete.delete_project">
    <querytext>
        select bt_project__delete(:project_id);
    </querytext>
  </fullquery>

  <fullquery name="bug_tracker::project_new.create_project">
    <querytext>
        select bt_project__new(:project_id);
    </querytext>
  </fullquery>

  <fullquery name="bug_tracker::category_get_filter_data_not_cached.select">
    <querytext>
        select kw.heading,
               km.keyword_id,
               count(b.bug_id)
        from   cr_keywords kw join
               cr_item_keyword_map km using (keyword_id) left outer join
               bt_bugs b on (b.bug_id = km.item_id)
        where  kw.parent_id = :parent_id
        and    b.project_id = :package_id
        group  by kw.heading, km.keyword_id
        order  by kw.heading
    </querytext>
  </fullquery>

  <fullquery name="bug_tracker::version_get_filter_data_not_cached.select">
    <querytext>
        select v.version_name,
               b.fix_for_version,
               count(b.bug_id) as num_bugs
        from   bt_bugs b left outer join 
               bt_versions v on (v.version_id = b.fix_for_version)
        where  b.project_id = :package_id
        group  by b.fix_for_version, v.anticipated_freeze_date, v.version_name
        order  by v.anticipated_freeze_date, v.version_name
    </querytext>
  </fullquery>

  <fullquery name="bug_tracker::assignee_get_filter_data_not_cached.select">
    <querytext>
      select p.first_names || ' ' || p.last_name as name,
             crum.user_id,
             count(b.bug_id) as num_bugs
      from   bt_bugs b,
             workflow_case_assigned_actions aa left outer join
             workflow_case_role_user_map crum on (crum.case_id = aa.case_id and crum.role_id = aa.role_id) left outer join
             persons p on (p.person_id = crum.user_id)
      where  aa.workflow_id = :workflow_id
      and    aa.action_id = :action_id
      and    aa.object_id = b.bug_id
      group  by p.first_names, p.last_name, crum.user_id
    </querytext>
  </fullquery>


   <fullquery name="bug_tracker::assignee_get_options.assignees">      
     <querytext>
       select acs_object__name(p.party_id) || ' (' || p.email || ')'  as label,
	party_id from  parties p
	where party_id in (select distinct(party_id) from workflow_case_role_party_map, 
				workflow_cases	
				where workflow_case_role_party_map.case_id = workflow_cases.case_id
				and workflow_cases.workflow_id = :workflow_id)
     </querytext>
    </fullquery>

   <fullquery name="bug_tracker::project_new.instance_info">      
     <querytext>
	select p.instance_name, o.creation_user, o.creation_ip 
	from apm_packages p join acs_objects o on (p.package_id = o.object_id) 
	where  p.package_id = :project_id      
     </querytext>
   </fullquery>

</queryset>
