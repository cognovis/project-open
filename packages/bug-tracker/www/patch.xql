<?xml version="1.0"?>
<queryset>

<fullquery name="patch_status">
      <querytext>
select status from bt_patches where patch_number = :patch_number and project_id = :package_id
      </querytext>
</fullquery>


<fullquery name="get_patch_content">
      <querytext>
select content from bt_patches where patch_number = :patch_number and project_id = :package_id
      </querytext>
</fullquery>


<fullquery name="actions">
      <querytext>
        select bt_patch_actions.action_id,
               bt_patch_actions.action,
               bt_patch_actions.actor as actor_user_id,
               actor.first_names as actor_first_names,
               actor.last_name as actor_last_name,
               actor.email as actor_email,
               bt_patch_actions.action_date,
               to_char(bt_patch_actions.action_date, 'fmMM/DDfm/YYYY') as action_date_pretty,
               bt_patch_actions.comment_text,
               bt_patch_actions.comment_format
        from   bt_patch_actions,
               cc_users actor
        where  bt_patch_actions.patch_id = :patch_id
        and    actor.user_id = bt_patch_actions.actor
        order  by action_date
      </querytext>
</fullquery>

<fullquery name="update_patch">
      <querytext>
        update bt_patches set    [join $update_exprs ", "] where  patch_id = :patch_id
      </querytext>
</fullquery>

<fullquery name="patch_action">
      <querytext>
            insert into bt_patch_actions
            (action_id, patch_id, action, actor, comment_text, comment_format)
            values
            (:action_id, :patch_id, :action, :user_id, :description, :desc_format)
      </querytext>
</fullquery>

<fullquery name="patch_id">
      <querytext>
          select patch_id from bt_patches where patch_number = :patch_number and project_id = :package_id
      </querytext>
</fullquery>

 <fullquery name="get_enabled_action_id">
      <querytext>
          select enabled_action_id from workflow_case_enabled_actions
          where action_id=:action_id and case_id=:case_id
      </querytext>
</fullquery>
  
</queryset>
