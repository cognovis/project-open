<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="object">      
      <querytext>
      
	select *
	from
	    (select 
		object_id, 
		object_type || ' - ' || acs_object__name(object_id) as name
	    from 
		acs_objects
	    where object_type not in (
			'im_biz_object_member', 'apm_package_version', 
			'content_revision', 'membership_rel', 'apm_parameter', 
			'im_cost', 'apm_parameter_value',
			'relationship', 'im_office', 'acs_sc_msg_type',
			'acs_sc_contract', 'acs_sc_implementation',
			'site_node', 'cr_item_rel', 'composition_rel',
			'user_portrait_rel', 'content_module', 'acs_sc_operation',
			'acs_object', 'content_folder', 'rel_segment', 
			'application_group', 'apm_package', 'content_item', 
			'acs_reference_repository', 'im_menu',
			'apm_service', 'authority', 'group', 
			'content_template', 'acs_mail_body', 'acs_mail_link', 
			'journal_entry' 
		)
	    ) o
	where
		name != ''
    order by 
	name

      </querytext>
</fullquery>

 
</queryset>
