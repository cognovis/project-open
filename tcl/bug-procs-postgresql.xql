<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

  <fullquery name="bug_tracker::bug::get.select_bug_data">
    <querytext>
      select b.bug_id,
             b.project_id,
             b.bug_number,
             b.summary,
             b.component_id,
             b.creation_date,
             to_char(b.creation_date, 'fmMM/DDfm/YYYY') as creation_date_pretty,
             b.resolution,
             b.user_agent,
             b.found_in_version,
             b.found_in_version,
             b.fix_for_version,
             b.fixed_in_version,
	     b.bug_container_project_id,
             to_char(now(), 'fmMM/DDfm/YYYY') as now_pretty
      from   bt_bugs b
      where  b.bug_id = :bug_id
    </querytext>
  </fullquery>

  <fullquery name="bug_tracker::bug::update.update_bug">
    <querytext>
        select bt_bug_revision__new (
            null,
            :bug_id,
            :component_id,
            :found_in_version,
            :fix_for_version,
            :fixed_in_version,
            :resolution,
            :user_agent,
            :summary,
            now(),
            :creation_user,
            :creation_ip,
	    :bug_container_project_id
        );
    </querytext>
  </fullquery>

  <fullquery name="bug_tracker::bug::insert.select_sysdate">
    <querytext>
        select current_timestamp
    </querytext>
  </fullquery>


<fullquery name="bug_tracker::bug::delete.delete_bug_case">
    <querytext> 
        select workflow_case_pkg__delete(:case_id);
    </querytext>
</fullquery>
 
<fullquery name="bug_tracker::bug::delete.delete_notification">
    <querytext>
        select notification__delete(:notification_id);
    </querytext>
</fullquery>

<fullquery name="bug_tracker::bug::delete.delete_cr_item">
    <querytext>
        select content_item__delete(:bug_id);
    </querytext>
</fullquery>

  <partialquery name="bug_tracker::bug::get_list.category_where_clause">
      <querytext>
         content_keyword__is_assigned(b.bug_id, :f_category_$parent_id, 'none') = 't'
      </querytext>
  </partialquery>

  <partialquery name="bug_tracker::bug::get_query.orderby_category_from_bug_clause">
      <querytext>
         left outer join cr_item_keyword_map km_order on (km_order.item_id = b.bug_id) 
         join cr_keywords kw_order on (km_order.keyword_id = kw_order.keyword_id and kw_order.parent_id = '[db_quote $orderby_parent_id]')
      </querytext>
  </partialquery>
 
  <partialquery name="bug_tracker::bug::get_query.orderby_category_where_clause">
      <querytext>
      </querytext>
  </partialquery>

<!-- bd: the inline view assign_info returns names
     of assignees as well as pretty_names of assigned actions.
     I'm left-outer-joining against this view.

     WARNING: In the query below I assume there can be at most one
     person assigned to a bug.  If more people are assigned you will get
     multiple rows per bug in the result set.  Current bug tracker
     doesn't have UI for creating such conditions. If you add UI that
     allows user to break this assumption you'll also need to deal with
     this.
-->
<fullquery name="bug_tracker::bug::get_query.bugs_pagination">
  <querytext>
    select b.bug_id,
           b.project_id,
           b.bug_number,
           b.summary,
           lower(b.summary) as lower_summary,
           b.comment_content,
           b.comment_format,
           b.component_id,
           b.creation_date,
           to_char(b.creation_date, 'fmMM/DDfm/YYYY') as creation_date_pretty,
           b.creation_user as submitter_user_id,
           submitter.first_names as submitter_first_names,
           submitter.last_name as submitter_last_name,
           submitter.email as submitter_email,
           lower(submitter.first_names) as lower_submitter_first_names,
           lower(submitter.last_name) as lower_submitter_last_name,
           lower(submitter.email) as lower_submitter_email,
           st.pretty_name as pretty_state,
           st.short_name as state_short_name,
           st.state_id,
           st.hide_fields,
           b.resolution,
           b.found_in_version,
           b.fix_for_version,
           b.fixed_in_version,
           cas.case_id
           $more_columns
    from $from_bug_clause,
         acs_users_all submitter,
         workflow_cases cas,
         workflow_case_fsm cfsm,
         workflow_fsm_states st 
    where submitter.user_id = b.creation_user
      and cas.workflow_id = :workflow_id
      and cas.object_id = b.bug_id
      and cfsm.case_id = cas.case_id
      and cfsm.parent_enabled_action_id is null
      and st.state_id = cfsm.current_state 
      $orderby_category_where_clause
    [template::list::filter_where_clauses -and -name "bugs"]
    [template::list::orderby_clause -orderby -name "bugs"]
  </querytext>
</fullquery>

<fullquery name="bug_tracker::bug::get_query.bugs">
  <querytext>
select q.*,
       km.keyword_id,
       assign_info.*
from (
  select b.bug_id,
         b.project_id,
         b.bug_number,
         b.summary,
         lower(b.summary) as lower_summary,
         b.comment_content,
         b.comment_format,
         b.component_id,
         b.creation_date,
         to_char(b.creation_date, 'fmMM/DDfm/YYYY') as creation_date_pretty,
         b.creation_user as submitter_user_id,
         submitter.first_names as submitter_first_names,
         submitter.last_name as submitter_last_name,
         submitter.email as submitter_email,
         lower(submitter.first_names) as lower_submitter_first_names,
         lower(submitter.last_name) as lower_submitter_last_name,
         lower(submitter.email) as lower_submitter_email,
         st.pretty_name as pretty_state,
         st.short_name as state_short_name,
         st.state_id,
         st.hide_fields,
         b.resolution,
         b.found_in_version,
         b.fix_for_version,
         b.fixed_in_version,
         bcp.project_name as bug_container_project_name,
	 bcpp.project_name as bug_container_parent_name,
         cas.case_id
         $more_columns
    from $from_bug_clause
	 left join im_projects bcp on (b.bug_container_project_id=bcp.project_id)
	 left join im_projects bcpp on (bcp.parent_id=bcpp.project_id),
         acs_users_all submitter,
         workflow_cases cas,
         workflow_case_fsm cfsm,
         workflow_fsm_states st 

   where submitter.user_id = b.creation_user
     and cas.workflow_id = :workflow_id
     and cas.object_id = b.bug_id
     and cfsm.case_id = cas.case_id
     and cfsm.parent_enabled_action_id is null
     and st.state_id = cfsm.current_state 
     and (b.bug_container_project_id IS NULL 
       OR ad_group_member_p( :current_user_id, bcp.project_id )='t'
       OR ad_group_member_p( :current_user_id, bcpp.project_id )='t'
     )
   $orderby_category_where_clause
   [template::list::page_where_clause -and -name bugs -key bug_id]
) q
left outer join
  cr_item_keyword_map km
on (bug_id = km.item_id)
left outer join
  (select cru.user_id as assigned_user_id,
          aa.action_id,
          aa.case_id,
          wa.pretty_name as action_pretty_name,
          p.first_names as assignee_first_names,
          p.last_name as assignee_last_name
     from workflow_case_assigned_actions aa,
          workflow_case_role_user_map cru,
          workflow_actions wa,
	  persons p
    where aa.case_id = cru.case_id
      and aa.role_id = cru.role_id
      and cru.user_id = p.person_id
      and wa.action_id = aa.action_id
  ) assign_info
on (q.case_id = assign_info.case_id)
   [template::list::orderby_clause -orderby -name "bugs"]
  </querytext>
</fullquery>


  <partialquery name="bug_tracker::bug::get_list.filter_assignee_null_where_clause">
      <querytext>
          exists (select 1
                  from workflow_case_assigned_actions aa left outer join
                    workflow_case_role_party_map wcrpm
                      on (wcrpm.case_id = aa.case_id and wcrpm.role_id = aa.role_id)
                  where aa.case_id = cas.case_id
                    and aa.action_id = $action_id
                    and wcrpm.party_id is null
                 )
      </querytext>
  </partialquery>

 
</queryset>
