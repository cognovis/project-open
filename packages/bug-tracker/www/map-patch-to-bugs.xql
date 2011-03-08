<?xml version="1.0"?>
<queryset>

<fullquery name="get_bug_id_for_number">
      <querytext>
select bug_id from bt_bugs where bug_number = :one_bug_number and project_id = :package_id
      </querytext>
</fullquery>

<fullquery name="get_patch_id_for_number">
      <querytext>
select patch_id from bt_patches where patch_number = :patch_number and project_id = :package_id
      </querytext>
</fullquery>

<fullquery name="get_patch_summary">
      <querytext>
select summary from bt_patches where patch_number = :patch_number and project_id = :package_id
      </querytext>
</fullquery>

<fullquery name="component_id_for_patch">
      <querytext>
select component_id from bt_patches where patch_number = :patch_number and project_id = :package_id
      </querytext>
</fullquery>

<fullquery name="bug_count_for_mapping">
      <querytext>
select count(*)
         from bt_bugs,
              workflow_cases cas,
              workflow_case_fsm cfsm
         where $sql_where_clause
      </querytext>
</fullquery>

</queryset>
