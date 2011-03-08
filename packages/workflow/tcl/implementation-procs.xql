<?xml version="1.0"?>
<queryset>

  <fullquery name="workflow::impl::role_default_assignees::creation_user::get_assignees.select_creation_user">
    <querytext>
      select creation_user
      from   acs_objects
      where  object_id = :object_id
    </querytext>
  </fullquery>

  <fullquery name="workflow::impl::role_default_assignees::creation_user::get_assignees.select_static_asignees">
    <querytext>
      select party_id
      from   workflow_role_default_parties
      where  role_id = :role_id
    </querytext>
  </fullquery>

  <fullquery name="workflow::impl::role_assignee_pick_list::current_assignees::get_pick_list.select_current_assignees">
    <querytext>
        select distinct m.party_id
        from   workflow_case_role_party_map m, 
               workflow_cases c
        where  m.role_id = :role_id 
        and    m.case_id = c.case_id
        and    c.workflow_id = (select workflow_id from workflow_cases where case_id = :case_id)
    </querytext>
  </fullquery>

  <partialquery name="workflow::impl::role_assignee_subquery::registered_users::get_subquery.cc_users">
    <querytext>
        cc_users
    </querytext>
  </partialquery>

</queryset>
