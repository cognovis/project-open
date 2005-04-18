<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

 
<fullquery name="content::check_access.ca_get_perm_list">      
      <querytext>
      
    select 
      p.privilege,
      cms_permission__permission_p (
        :object_id, :user_id, p.privilege
      ) as is_granted
    from 
      acs_privileges p
      </querytext>
</fullquery>

 
<fullquery name="content::check_access.ca_get_msg_info">      
      <querytext>
      
	select 
	  acs_object__name(:object_id) as obj_name, 
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
	lpad(' ', t.tree_level * 24, '&nbsp;') || coalesce(p.pretty_name, t.child_privilege) as label,
	cms_permission__permission_p(:object_id, :grantee_id, t.child_privilege) as permission_p,
        cms_permission__permission_p (:object_id, :grantee_id, t.privilege) as parent_permission_p
      from (select h1.privilege, h1.child_privilege, 
                tree_level(h1.tree_sortkey) as tree_level
	   from acs_privilege_hierarchy_index h1, acs_privilege_hierarchy_index h2
           where h2.privilege = 'cm_root'
             and h1.tree_sortkey between h2.tree_sortkey and tree_right(h2.tree_sortkey)
             and tree_ancestor_p(h2.tree_sortkey, h1.tree_sortkey)
	) t, acs_privileges p
      where
	p.privilege = t.child_privilege
      and (
	cms_permission__has_grant_authority (
	  :object_id, :user_id, t.child_privilege
	) = 't' 
	or
	cms_permission__has_revoke_authority (
	  :object_id, :user_id, t.child_privilege, :grantee_id
	) = 't' 
      )

	</querytext>
</partialquery>


<partialquery name="content::perm_form_process.pfp_grant_permission_1">
	<querytext>
                 
     select cms_permission__grant_permission (:object_id, :user_id, :privilege, :grantee_id, :pf_is_recursive)

	</querytext>
</partialquery>


<partialquery name="content::perm_form_process.pfp_revoke_permission_1">
	<querytext>

     select cms_permission__revoke_permission (:object_id, :user_id, :privilege, :grantee_id, :pf_is_recursive)

	</querytext>
</partialquery>


</queryset>
