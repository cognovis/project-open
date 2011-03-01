<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="patch">
  <querytext>
     select bt_patches.patch_id,
            bt_patches.patch_number,
            bt_patches.project_id,
            bt_patches.component_id,
            bt_patches.summary,
            bt_patches.content,
            bt_patches.generated_from_version,
            bt_patches.apply_to_version,
            bt_patches.applied_to_version,
            bt_patches.status,
            bt_components.component_name,
            acs_objects.creation_user as submitter_user_id,
            submitter.first_names as submitter_first_names,
            submitter.last_name as submitter_last_name,
            submitter.email as submitter_email,
            acs_objects.creation_date,
            to_char(acs_objects.creation_date, 'fmMM/DDfm/YYYY') as creation_date_pretty,
            to_char(sysdate, 'fmMM/DDfm/YYYY') as now_pretty
     from bt_patches,
          acs_objects,
	  acs_users_all submitter,
          bt_components
     where bt_patches.patch_number = :patch_number
       and bt_patches.project_id = :package_id
       and bt_patches.patch_id = acs_objects.object_id
       and bt_patches.component_id = bt_components.component_id
       and submitter.user_id = acs_objects.creation_user
  </querytext>
</fullquery>

</queryset>
