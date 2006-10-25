<?xml version="1.0"?>
<queryset>

<fullquery name="bug_tracker::bug::cache_flush.get_project_id">
    <querytext>
      select project_id from bt_bugs where bug_id = :bug_id
    </querytext>
</fullquery>

<fullquery name="bug_tracker::bug::delete.get_case_id">
    <querytext>
        select case_id
        from   workflow_cases
        where  object_id = :bug_id
    </querytext>
</fullquery>

<fullquery name="bug_tracker::bug::delete.get_notifications">
    <querytext>
        select notification_id
        from   notifications
        where  response_id = :bug_id
    </querytext>
</fullquery>

<fullquery name="bug_tracker::bug::delete.unset_revisions">
    <querytext>
        update cr_items
        set live_revision = null, latest_revision = null
        where item_id = :bug_id
    </querytext>
</fullquery>

  <fullquery name="bug_tracker::bug::get_activity_html.actions">
    <querytext>
      select ba.action_id,
             ba.action as loop_action,
             ba.resolution,
             ba.actor as actor_user_id,
             actor.first_names as actor_first_names,
             actor.last_name as actor_last_name,
             actor.email as actor_email,
             ba.action_date,
             to_char(ba.action_date, 'fmMM/DDfm/YYYY') as action_date_pretty,
             ba.comment_s,
             ba.comment_format
      from   bt_bug_actions ba,
             cc_users actor
      where  ba.bug_id = :bug_id
      and    actor.user_id = ba.actor
      order  by action_date
    </querytext>
  </fullquery>

  <fullquery name="bug_tracker::bug::capture_resolution_code::do_side_effect.select_resolution_code">
    <querytext>
        select resolution
        from   bt_bugs
        where  bug_id = :object_id
    </querytext>
  </fullquery>

  <fullquery name="bug_tracker::bug::get_component_maintainer::get_assignees.select_component_maintainer">
    <querytext>
        select c.maintainer
        from   bt_components c,
               bt_bugs b
        where  b.bug_id = :object_id
        and    c.component_id = b.component_id
    </querytext>
  </fullquery>

  <fullquery name="bug_tracker::bug::get_project_maintainer::get_assignees.select_project_maintainer">
    <querytext>
        select p.maintainer
        from   bt_projects p,
               bt_bugs b
        where  b.bug_id = :object_id
        and    p.project_id = b.project_id
    </querytext>
  </fullquery>

  <fullquery name="bug_tracker::bug::notification_info::get_notification_info.select_notification_tag">
    <querytext>
        select email_subject_name
        from   bt_projects p,
               bt_bugs b
        where  b.bug_id = :object_id
        and    p.project_id = b.project_id
    </querytext>
  </fullquery>
 
  <partialquery name="bug_tracker::bug::get_list.filter_assignee_where_clause">
      <querytext>
          exists (select 1
                  from   workflow_case_assigned_actions aa,
                    workflow_case_role_party_map wcrpm
                  where  aa.case_id = cas.case_id
                  and    aa.action_id = $action_id
                  and    wcrpm.case_id = aa.case_id
                  and    wcrpm.role_id = aa.role_id
                  and    wcrpm.party_id = :f_action_$action_id
                 )
      </querytext>
  </partialquery>

</queryset>

