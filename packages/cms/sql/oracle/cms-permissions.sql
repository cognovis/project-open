-- This file will eventually replace content-perms.sql
-- Implements the CMS permission

declare 
  v_perms varchar2(1) := 'f';
begin
  
  begin
    select 't' into v_perms from dual 
    where exists (select 1 from acs_privileges 
                  where privilege = 'cm_root');
  exception when no_data_found then
    v_perms := 'f';
  end;

  if v_perms <> 't' then

    -- Dummy root privilege
    acs_privilege.create_privilege('cm_root', 'Root', 'Root');
    -- He can do everything
    acs_privilege.create_privilege('cm_admin', 'Administrator', 'Administrators');
    acs_privilege.create_privilege('cm_relate', 'Relate Items', 'Relate Items');
    acs_privilege.create_privilege('cm_write', 'Write', 'Write');    
    acs_privilege.create_privilege('cm_new', 'Create New Item', 'Create New Item');    
    acs_privilege.create_privilege('cm_examine', 'Admin-level Read', 'Admin-level Read');    
    acs_privilege.create_privilege('cm_read', 'User-level Read', 'User-level Read');    
    acs_privilege.create_privilege('cm_item_workflow', 'Modify Workflow', 'Modify Workflow');    
    acs_privilege.create_privilege('cm_perm_admin', 'Modify Any Permissions', 'Modify Any Permissions');    
    acs_privilege.create_privilege('cm_perm', 'Donate Permissions', 'Donate Permissions');    

    acs_privilege.add_child('cm_root', 'cm_admin');           -- Do anything
    acs_privilege.add_child('cm_admin', 'cm_relate');         -- Related/Child items
    acs_privilege.add_child('cm_relate', 'cm_write');         -- Modify the item
    acs_privilege.add_child('cm_write', 'cm_new');            -- Create subitems
    acs_privilege.add_child('cm_new', 'cm_examine');          -- View in admin mode 
    acs_privilege.add_child('cm_examine', 'cm_read');         -- View in user mode
    acs_privilege.add_child('cm_admin', 'cm_item_workflow');  -- Change item workflow

    acs_privilege.add_child('cm_admin', 'cm_perm_admin');     -- Modify any permissions
    acs_privilege.add_child('cm_perm_admin', 'cm_perm');      -- Modify any permissions on an item

    -- Proper inheritance
    acs_privilege.add_child('admin', 'cm_root');

  end if;
  
end;
/
show errors

create or replace package cms_permission 
is
  procedure update_permissions (
    --/** Make the child item inherit all of the permissions of the parent
    --    item. Typically, this function is called whenever permissions on
    --    an item are changed for the first time.
    --    @author Stanislav Freidin
    --    @param item_id      The item_id
    --    @param is_recursive If 'f', update child items as well, otherwise
    --        update only the item itself (note: this is the opposite of
    --        is_recursive in grant_permission and revoke_permission)
    --    @see {cms_permission.grant_permission}, {cms_permission.copy_permissions}
    --*/  
    item_id           in cr_items.item_id%TYPE,
    is_recursive      in varchar2 default 't'
  );

  function has_grant_authority (
    --/** Determine if the user may grant a certain permission to another
    --    user. The permission may only be granted if the user has 
    --    the permission himself and posesses the cm_perm access, or if the
    --    user posesses the cm_perm_admin access.
    --    @author Stanislav Freidin
    --    @param item_id     The item whose permissions are to be changed
    --    @param holder_id   The person who is attempting to grant the permissions
    --    @param privilege   The privilege to be granted
    --    @return 't' if the donation is possible, 'f' otherwise
    --    @see {cms_permission.grant_permission}, 
    --         {cms_permission.is_has_revoke_authority},
    --         {acs_permission.grant_permission}
    --*/
    item_id           in cr_items.item_id%TYPE,
    holder_id         in parties.party_id%TYPE, 
    privilege         in acs_privileges.privilege%TYPE
  ) return varchar2;
   
  procedure grant_permission (
    --/** Grant the specified privilege to another user. If the donation is
    --    not possible, the procedure does nothing.
    --    @author Stanislav Freidin
    --    @param item_id       The item whose permissions are to be changed
    --    @param holder_id     The person who is attempting to grant the permissions
    --    @param privilege     The privilege to be granted
    --    @param recepient_id  The person who will gain the privilege 
    --    @param is_recursive  If 't', applies the donation recursively to
    --      all child items of the item (equivalent to UNIX's <tt>chmod -r</tt>).
    --      If 'f', only affects the item itself.
    --    @see {cms_permission.has_grant_authority}, 
   --          {cms_permission.revoke_permission},
    --         {acs_permission.grant_permission}
    --*/
    item_id           in cr_items.item_id%TYPE,
    holder_id         in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE,
    recepient_id      in parties.party_id%TYPE,
    is_recursive      in varchar2 default 'f'
  );

  function has_revoke_authority (
    --/** Determine if the user may take a certain permission away from another
    --    user. The permission may only be revoked if the user has 
    --    the permission himself and posesses the cm_perm access, while the
    --    other user does not, or if the user posesses the cm_perm_admin access.
    --    @author Stanislav Freidin
    --    @param item_id     The item whose permissions are to be changed
    --    @param holder_id   The person who is attempting to revoke the permissions
    --    @param privilege   The privilege to be revoked
    --    @param revokee_id  The user from whom the privilege is to be taken away
    --    @return 't' if it is possible to revoke the privilege, 'f' otherwise
    --    @see {cms_permission.has_grant_authority}, 
    --         {cms_permission.revoke_permission},
    --         {acs_permission.revoke_permission}
    --*/
    item_id           in cr_items.item_id%TYPE,
    holder_id         in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE,
    revokee_id        in parties.party_id%TYPE
  ) return varchar2;

  procedure revoke_permission (
    --/** Take the specified privilege away from another user. If the operation is
    --    not possible, the procedure does nothing.
    --    @author Stanislav Freidin
    --    @param item_id       The item whose permissions are to be changed
    --    @param holder_id     The person who is attempting to revoke the permissions
    --    @param privilege     The privilege to be revoked 
    --    @param recepient_id  The person who will lose the privilege 
    --    @param is_recursive  If 't', applies the operation recursively to
    --      all child items of the item (equivalent to UNIX's <tt>chmod -r</tt>).
    --      If 'f', only affects the iten itself.
    --    @see {cms_permission.grant_permission}, 
    --         {cms_permission.has_revoke_authority},
    --         {acs_permission.revoke_permission}
    --*/
    item_id           in cr_items.item_id%TYPE,
    holder_id         in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE,
    revokee_id        in parties.party_id%TYPE,
    is_recursive      in varchar2 default 'f'
  );

  function permission_p (
    --/** Determine if the user has the specified permission on the specified 
    --    object. Does NOT check objects recursively: that is, if the user has
    --    the permission on the parent object, he does not automatically gain 
    --    the permission on all the child objects.<p>
    --    In addition, checks if the Publishing workflow has been assigned to
    --    the item. If it has, then the user must be assigned to the current 
    --    workflow task in order to utilize his cm_relate, cm_write or cm_new
    --    permission.
    --    @author Stanislav Freidin
    --    @param item_id       The object whose permissions are to be checked
    --    @param holder_id     The person whose permissions are to be examined
    --    @param privilege     The privilege to be checked
    --    @return 't' if the user has the specified permission on the item, 
    --                'f' otherwise
    --    @see {cms_permission.grant_permission}, {cms_permission.revoke_permission},
    --         {acs_permission.permission_p}
    --*/
    item_id           in cr_items.item_id%TYPE,
    holder_id         in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE
  ) return varchar2;

  function cm_admin_exists 
    --/** Determine if there exists a user who has administrative 
    --     privileges on the entire content repository.
    --     @author Stanislav Freidin
    --     @return 't' if an administrator exists, 'f' otherwise
    --     @see {cms_permission.grant_permission}
    --*/
  return varchar2;

end cms_permission;
/
show errors


create or replace package body cms_permission
is

  procedure update_permissions (
    item_id           in cr_items.item_id%TYPE,
    is_recursive      in varchar2 default 'f'
  )
  is
    v_grantee_id   parties.party_id%TYPE;
    v_privilege    acs_privileges.privilege%TYPE;
    v_inherit_p    varchar2(1);
    v_context_id   acs_objects.context_id%TYPE;
  
    cursor c_child_cur is
      select item_id from cr_items 
        where parent_id = update_permissions.item_id;
  begin
     
    -- If there is no inheritance, nothing to do
    select security_inherit_p, context_id 
     into v_inherit_p, v_context_id
     from acs_objects
    where object_id = update_permissions.item_id;
  
    if v_inherit_p = 'f' or v_context_id is null then
      return;
    end if; 

    -- Remove inheritance on the item
    update acs_objects set security_inherit_p = 'f' 
      where object_id = update_permissions.item_id;

    -- If not recursive, turn off inheritance for children of
    -- this item
    if is_recursive = 'f' then
      update 
        acs_objects 
      set
        security_inherit_p = 'f'
      where 
        object_id in (
          select item_id from cr_items 
            where parent_id = update_permissions.item_id
        )
      and
        security_inherit_p = 't';
    end if;

    -- Get permissions assigned to the parent(s), copy them into child
    declare
      cursor c_perm_cur is
        select 
          p.grantee_id, p.privilege
        from 
          acs_permissions p,
          (select object_id from acs_objects 
            connect by prior context_id = object_id 
                   and security_inherit_p = 't'
            start with object_id = v_context_id) o
        where  
          p.object_id = o.object_id;
    begin
      open c_perm_cur;
      loop
        fetch c_perm_cur into v_grantee_id, v_privilege; 
        exit when c_perm_cur%NOTFOUND;
        if acs_permission.permission_p (
             item_id, v_grantee_id, v_privilege
           ) = 'f' 
        then
          acs_permission.grant_permission (
            item_id, v_grantee_id, v_privilege
          );
        end if;
      end loop;
      close c_perm_cur;
    end;
   
  end update_permissions;

  function has_grant_authority ( 
    item_id           in cr_items.item_id%TYPE,
    holder_id         in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE
  ) return varchar2
  is
  begin
    -- Can donate permission only if you already have it and you have cm_perm,
    -- OR you have cm_perm_admin
    if acs_permission.permission_p (item_id, holder_id, 'cm_perm_admin')= 't' 
       or (
         acs_permission.permission_p (item_id, holder_id, 'cm_perm') = 't' and
         acs_permission.permission_p (item_id, holder_id, privilege) = 't'
       ) 
    then
      return 't';
    else
      return 'f';
    end if;
  end has_grant_authority;

  function has_revoke_authority (
    item_id           in cr_items.item_id%TYPE,
    holder_id         in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE,
    revokee_id        in parties.party_id%TYPE
  ) return varchar2
  is
    cursor c_perm_cur is
      select 
        't' 
      from 
        acs_privilege_hierarchy
      where
        acs_permission.permission_p(
          has_revoke_authority.item_id, 
          has_revoke_authority.holder_id, 
          child_privilege
        ) = 't'
      and
        acs_permission.permission_p(
          has_revoke_authority.item_id, 
          has_revoke_authority.revokee_id,
          privilege
        ) = 'f'
      connect by 
        prior privilege = child_privilege
      start with 
        child_privilege = 'cm_perm';

    v_ret varchar2(1);   
  begin
    open c_perm_cur;
    fetch c_perm_cur into v_ret;
    if c_perm_cur%NOTFOUND then
      v_ret := 'f';
    end if;
    close c_perm_cur;
    return v_ret;
  end has_revoke_authority;

  procedure grant_permission (
    item_id           in cr_items.item_id%TYPE,
    holder_id         in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE,
    recepient_id      in parties.party_id%TYPE,
    is_recursive      in varchar2 default 'f'
  )
  is
    cursor c_item_cur is
      select 
        item_id 
      from 
        (select item_id from cr_items 
           connect by parent_id = prior item_id
           start with item_id = grant_permission.item_id) i
      where
        has_grant_authority (
          i.item_id, grant_permission.holder_id, grant_permission.privilege
        ) = 't'
      and 
        acs_permission.permission_p (
          i.item_id, grant_permission.recepient_id, grant_permission.privilege
        ) = 'f';
 
    v_item_id    cr_items.item_id%TYPE;

    type item_array_type is table of cr_items.item_id%TYPE 
      index by binary_integer;
    v_items      item_array_type;
    v_idx        integer;
    v_count      integer;

    cursor c_perm_cur is
      select descendant from acs_privilege_descendant_map
      where privilege = grant_permission.privilege
      and   descendant <> grant_permission.privilege;

    type perm_array_type is table of acs_privileges.privilege%TYPE 
      index by binary_integer;

    v_perms      perm_array_type;
    v_perm       acs_privileges.privilege%TYPE;
    v_perm_idx   integer;
    v_perm_count integer;
  begin

    update_permissions(item_id, is_recursive);
  
    -- Select all child items
    open c_item_cur;
    v_count := 0;
    loop
      fetch c_item_cur into v_item_id;
      exit when c_item_cur%NOTFOUND; 
      v_count := v_count + 1;
      v_items(v_count) := v_item_id;
      exit when is_recursive = 'f';
    end loop;
    close c_item_cur;   

    if v_count < 1 then 
      return;
    end if;

    -- Grant parent permission
    for v_idx in 1..v_count loop
      acs_permission.grant_permission (
        v_items(v_idx), recepient_id, privilege
      );
    end loop;  

    -- Select the child permissions
    v_perm_count := 0;
    open c_perm_cur;
    loop
      fetch c_perm_cur into v_perm;
      exit when c_perm_cur%NOTFOUND;
      v_perm_count := v_perm_count + 1;
      v_perms(v_perm_count) := v_perm;
    end loop;
    close c_perm_cur;    

    -- Revoke child permissions
    for v_idx in 1..v_count loop
      for v_perm_idx in 1..v_perm_count loop
        acs_permission.revoke_permission (
          v_items(v_idx), recepient_id, v_perms(v_perm_idx)
        );
       end loop;
    end loop;
  
  end grant_permission;
         

  procedure revoke_permission (
    item_id           in cr_items.item_id%TYPE,
    holder_id         in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE,
    revokee_id        in parties.party_id%TYPE,
    is_recursive      in varchar2 default 'f'
  )
  is
 
    cursor c_item_cur is
      select item_id from cr_items
        connect by parent_id = prior item_id
        start with item_id = revoke_permission.item_id
      where
        has_revoke_authority (
          item_id, 
          cms_permission.revoke_permission.holder_id,
          cms_permission.revoke_permission.privilege,
          cms_permission.revoke_permission.revokee_id
        ) = 't'
      and
        acs_permission.permission_p (
          item_id,
          cms_permission.revoke_permission.revokee_id,
          cms_permission.revoke_permission.privilege
        ) = 't';

    cursor c_perm_cur is
      select
        child_privilege
      from 
        acs_privilege_hierarchy
      where 
        privilege = revoke_permission.privilege
      and 
        child_privilege <> revoke_permission.privilege;

    type item_array_type is table of cr_items.item_id%TYPE 
      index by binary_integer;
    v_items      item_array_type;
    v_item_id    cr_items.item_id%TYPE;
    v_idx        integer;
    v_count      integer;

    type perm_array_type is table of acs_privileges.privilege%TYPE 
      index by binary_integer;

    v_perms      perm_array_type;
    v_perm       acs_privileges.privilege%TYPE;
    v_perm_idx   integer;
    v_perm_count integer;
  begin
  
    update_permissions(item_id, is_recursive);

    -- Select the child permissions
    v_perm_count := 0;
    open c_perm_cur;
    loop
      fetch c_perm_cur into v_perm;
      exit when c_perm_cur%NOTFOUND;
      v_perm_count := v_perm_count + 1;
      v_perms(v_perm_count) := v_perm;
    end loop;
    close c_perm_cur;

    -- Select child items 
    v_count := 0;
    open c_item_cur;
    loop
      fetch c_item_cur into v_item_id;
      exit when c_item_cur%NOTFOUND; 
      v_count := v_count + 1;
      v_items(v_count) := v_item_id;
      exit when is_recursive = 'f';
    end loop;
    close c_item_cur;   

    if v_count < 1 then 
      return;
    end if;

    -- Grant child permissions
    for v_idx in 1..v_count loop
      for v_perm_idx in 1..v_perm_count loop
        acs_permission.grant_permission (
          v_items(v_idx), revokee_id, v_perms(v_perm_idx)
        );
       end loop;
    end loop;  

    -- Revoke the parent permission
    for v_idx in 1..v_count loop
      acs_permission.revoke_permission (
        v_items(v_idx), 
        revoke_permission.revokee_id, 
        revoke_permission.privilege
      );
    end loop;  

  end revoke_permission;  

  function permission_p (
    item_id           in cr_items.item_id%TYPE,
    holder_id         in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE
  ) return varchar2
  is
    v_workflow_count integer;
    v_task_count     integer;
  begin
      
    -- Check permission the old-fashioned way first
    if acs_permission.permission_p (
         item_id, holder_id, privilege
       ) = 'f' 
    then
      return 'f';
    end if;
  
    -- Special case for workflow

    if privilege = 'cm_relate' or 
       privilege = 'cm_write' or 
       privilege = 'cm_new' 
    then

      -- Check if the publishing workflow exists, and if it
      -- is the only workflow that exists
      select
        count(case_id) into v_workflow_count
      from
        wf_cases
      where
        object_id = permission_p.item_id;

      -- If there are multiple workflows / no workflows, do nothing
      -- special
      if v_workflow_count <> 1 then
        return 't';
      end if;       
        
      -- Even if there is a workflow, the user can touch the item if he
      -- has cm_item_workflow
      if acs_permission.permission_p (
         item_id, holder_id, 'cm_item_workflow'
       ) = 't' 
      then
        return 't';
      end if;

      -- Check if the user holds the current task
      if v_workflow_count = 0 then
	return 'f';
      end if;

      select
	count(task_id) into v_task_count
      from
	wf_user_tasks t, wf_cases c
      where
	t.case_id = c.case_id
      and
	c.workflow_key = 'publishing_wf'
      and
	c.state = 'active'
      and
	c.object_id = permission_p.item_id
      and
	( t.state = 'enabled' 
	  or 
	    ( t.state = 'started' and t.holding_user = permission_p.holder_id ))
      and
	t.user_id = permission_p.holder_id;

      -- is the user assigned a current task on this item
      if v_task_count = 0 then
	return 'f';
      end if;      

    end if;

    return 't';
 
  end permission_p;

  -- Determine if the CMS admin exists
  function cm_admin_exists 
  return varchar2
  is
    v_exists varchar2(1);
  begin
    
    select 't' into v_exists from dual 
     where exists (
       select 1 from acs_permissions 
       where privilege in ('cm_admin', 'cm_root')
     );

    return v_exists;

  exception when no_data_found then
    return 'f';
  end cm_admin_exists;

end cms_permission;
/
show errors

-- A trigger to automatically grant item creators the cm_write and cm_perm
-- permissions

create or replace trigger cr_items_permission_tr
after insert on cr_items for each row
declare
  v_user_id parties.party_id%TYPE;
begin
  
  select creation_user into v_user_id from acs_objects
    where object_id = :new.item_id;

  if v_user_id is not null then

    if acs_permission.permission_p (
        :new.item_id, v_user_id, 'cm_write'
       ) = 'f' 
    then
      acs_permission.grant_permission (
        :new.item_id, v_user_id, 'cm_write'
      );
    end if;
  
    if acs_permission.permission_p (
        :new.item_id, v_user_id, 'cm_perm'
       ) = 'f' 
    then
      acs_permission.grant_permission (
        :new.item_id, v_user_id, 'cm_perm'
      );
    end if; 
  end if;

exception when no_data_found then null;
   
end cr_items_permission_tr;
/
show errors
         
        
-- A simple wrapper for acs-content-repository procs   
    
create or replace package content_permission 
is

  procedure inherit_permissions (
    parent_object_id  in acs_objects.object_id%TYPE,
    child_object_id   in acs_objects.object_id%TYPE,
    child_creator_id  in parties.party_id%TYPE default null
  );

  function has_grant_authority (
    object_id         in acs_objects.object_id%TYPE,
    holder_id         in parties.party_id%TYPE, 
    privilege         in acs_privileges.privilege%TYPE
  ) return varchar2;
   
  procedure grant_permission_h (
    object_id         in acs_objects.object_id%TYPE,
    grantee_id        in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE
  );

  procedure grant_permission (
    object_id         in acs_objects.object_id%TYPE,
    holder_id         in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE,
    recepient_id      in parties.party_id%TYPE,
    is_recursive      in varchar2 default 'f',
    object_type       in acs_objects.object_type%TYPE default 'content_item'
  );

  function has_revoke_authority (
    object_id         in acs_objects.object_id%TYPE,
    holder_id         in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE,
    revokee_id        in parties.party_id%TYPE
  ) return varchar2;

  procedure revoke_permission_h (
    object_id         in acs_objects.object_id%TYPE,
    revokee_id        in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE
  );

  procedure revoke_permission (
    object_id         in acs_objects.object_id%TYPE,
    holder_id         in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE,
    revokee_id        in parties.party_id%TYPE,
    is_recursive      in varchar2 default 'f',
    object_type       in acs_objects.object_type%TYPE default 'content_item'
  );

  function permission_p (
    object_id         in acs_objects.object_id%TYPE,
    holder_id         in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE
  ) return varchar2;

  function cm_admin_exists 
  return varchar2;

end content_permission;
/
show errors


create or replace package body content_permission 
is

  procedure inherit_permissions (
    parent_object_id  in acs_objects.object_id%TYPE,
    child_object_id   in acs_objects.object_id%TYPE,
    child_creator_id  in parties.party_id%TYPE default null
  )
  is
  begin
    cms_permission.update_permissions(child_object_id);
  end inherit_permissions;

  function has_grant_authority (
    object_id         in acs_objects.object_id%TYPE,
    holder_id         in parties.party_id%TYPE, 
    privilege         in acs_privileges.privilege%TYPE
  ) return varchar2
  is
  begin
    return cms_permission.has_grant_authority (
      object_id, holder_id, privilege
    );
  end has_grant_authority;
   
  procedure grant_permission_h (
    object_id         in acs_objects.object_id%TYPE,
    grantee_id        in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE
  )
  is
  begin
    return;
  end;

  procedure grant_permission (
    object_id         in acs_objects.object_id%TYPE,
    holder_id         in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE,
    recepient_id      in parties.party_id%TYPE,
    is_recursive      in varchar2 default 'f',
    object_type       in acs_objects.object_type%TYPE default 'content_item'
  ) 
  is
  begin
    cms_permission.grant_permission (
      object_id, holder_id, privilege, recepient_id, is_recursive
    );
  end grant_permission;

  function has_revoke_authority (
    object_id         in acs_objects.object_id%TYPE,
    holder_id         in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE,
    revokee_id        in parties.party_id%TYPE
  ) return varchar2
  is
  begin
    return cms_permission.has_revoke_authority (
      object_id, holder_id, privilege, revokee_id
    );
  end has_revoke_authority;

  procedure revoke_permission_h (
    object_id         in acs_objects.object_id%TYPE,
    revokee_id        in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE
  )
  is
  begin
    return;
  end revoke_permission_h;

  procedure revoke_permission (
    object_id         in acs_objects.object_id%TYPE,
    holder_id         in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE,
    revokee_id        in parties.party_id%TYPE,
    is_recursive      in varchar2 default 'f',
    object_type       in acs_objects.object_type%TYPE default 'content_item'
  )
  is
  begin
    cms_permission.revoke_permission (
      object_id, holder_id, privilege, revokee_id, is_recursive
    );
  end revoke_permission;

  function permission_p (
    object_id         in acs_objects.object_id%TYPE,
    holder_id         in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE
  ) return varchar2
  is
  begin
    return cms_permission.permission_p (
      object_id, holder_id, privilege
    );
  end permission_p;

  function cm_admin_exists 
  return varchar2
  is
  begin
    return cms_permission.cm_admin_exists;
  end cm_admin_exists;

end content_permission;
/
show errors
      









