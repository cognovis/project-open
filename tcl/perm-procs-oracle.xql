<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>
 
<fullquery name="content::check_access.ca_get_perm_list">      
      <querytext>
      
    select 
      p.privilege,
      cms_permission.permission_p (
        :object_id, :user_id, p.privilege
      ) as is_granted
    from 
      acs_privileges p
      </querytext>
</fullquery>

 
<fullquery name="content::check_access.ca_get_msg_info">      
      <querytext>
      
	select 
	  acs_object.name(:object_id) as obj_name, 
	  pretty_name as perm_name
	from 
	  acs_privileges
	where 
	  privilege = :privilege
      </querytext>
</fullquery>

<partialquery name="content::perm_form_generate.pfg_get_permission_boxes">
	<querytext>

      select 
	t.child_privilege as privilege, 
	lpad(' ', t.tree_level * 24, '&nbsp;') || 
          NVL(p.pretty_name, t.child_privilege) as label,
	cms_permission.permission_p(
	 :object_id, :grantee_id, t.child_privilege
	) as permission_p,
        cms_permission.permission_p (
	 :object_id, :grantee_id, t.privilege
	) as parent_permission_p
      from (
	select privilege, child_privilege, level as tree_level
	  from acs_privilege_hierarchy
	  connect by privilege = prior child_privilege
	  start with privilege = 'cm_root'
	) t, acs_privileges p
      where
	p.privilege = t.child_privilege
      and (
	cms_permission.has_grant_authority (
	  :object_id, :user_id, t.child_privilege
	) = 't' 
	or
	cms_permission.has_revoke_authority (
	  :object_id, :user_id, t.child_privilege, :grantee_id
	) = 't' 
      )

	</querytext>
</partialquery>

<partialquery name="content::perm_form_process.pfp_grant_permission_1">
	<querytext>
                     begin 
	               cms_permission.grant_permission (
		         item_id => :object_id, 
		         holder_id => :user_id,
		         privilege => :privilege, 
		         recepient_id => :grantee_id,
                         is_recursive => :pf_is_recursive
	               );
	             end;

	</querytext>
</partialquery>

<partialquery name="content::perm_form_process.pfp_revoke_permission_1">
	<querytext>
                     begin 
     	               cms_permission.revoke_permission (
		         item_id => :object_id, 
		         holder_id => :user_id,
		         privilege => :privilege, 
		         revokee_id => :grantee_id,
                         is_recursive => :pf_is_recursive
	               );
	             end;

	</querytext>
</partialquery>

</queryset>
