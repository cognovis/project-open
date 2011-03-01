-- This file will eventually replace content-perms.sql
-- Implements the CMS permission

create or replace function inline_0 ()
returns integer as '
declare
  v_perms       boolean default ''f'';
begin
    
  select ''t'' into v_perms from dual 
  where exists (select 1 from acs_privileges 
                 where privilege = ''cm_root'');

  if NOT FOUND then
     v_perms := ''f'';
  end if;

  if v_perms <> ''t'' then


    -- Dummy root privilege
    PERFORM acs_privilege__create_privilege(''cm_root'', ''Root'', ''Root'');
    -- He can do everything
    PERFORM acs_privilege__create_privilege(''cm_admin'', ''Administrator'', ''Administrators'');
    PERFORM acs_privilege__create_privilege(''cm_relate'', ''Relate Items'', ''Relate Items'');
    PERFORM acs_privilege__create_privilege(''cm_write'', ''Write'', ''Write'');    
    PERFORM acs_privilege__create_privilege(''cm_new'', ''Create New Item'', ''Create New Item'');    
    PERFORM acs_privilege__create_privilege(''cm_examine'', ''Admin-level Read'', ''Admin-level Read'');    
    PERFORM acs_privilege__create_privilege(''cm_read'', ''User-level Read'', ''User-level Read'');    
    PERFORM acs_privilege__create_privilege(''cm_item_workflow'', ''Modify Workflow'', ''Modify Workflow'');    
    PERFORM acs_privilege__create_privilege(''cm_perm_admin'', ''Modify Any Permissions'', ''Modify Any Permissions'');
    
    PERFORM acs_privilege__create_privilege(''cm_perm'', ''Donate Permissions'', ''Donate Permissions'');    

    PERFORM acs_privilege__add_child(''cm_root'', ''cm_admin'');           -- Do anything
    PERFORM acs_privilege__add_child(''cm_admin'', ''cm_relate'');         -- Related/Child items
    PERFORM acs_privilege__add_child(''cm_relate'', ''cm_write'');         -- Modify the item
    PERFORM acs_privilege__add_child(''cm_write'', ''cm_new'');            -- Create subitems
    PERFORM acs_privilege__add_child(''cm_new'', ''cm_examine'');          -- View in admin mode 
    PERFORM acs_privilege__add_child(''cm_examine'', ''cm_read'');         -- View in user mode
    PERFORM acs_privilege__add_child(''cm_admin'', ''cm_item_workflow'');  -- Change item workflow

    PERFORM acs_privilege__add_child(''cm_admin'', ''cm_perm_admin'');     -- Modify any permissions

    PERFORM acs_privilege__add_child(''cm_perm_admin'', ''cm_perm'');      -- Modify any permissions on an item


    -- Proper inheritance
    -- PERFORM acs_privilege__add_child(''admin'', ''cm_root'');

  end if;
  
  return 0;
end;' language 'plpgsql';


select inline_0 ();


drop function inline_0 ();

select acs_privilege__add_child('admin', 'cm_root') 
from dual 
where not exists (select 1 
                    from acs_privilege_hierarchy 
                   where privilege = 'admin' 
                     and child_privilege = 'cm_root') 
limit 1;


-- show errors

-- create or replace package cms_permission 
-- is
--   procedure update_permissions (
--     --/** Make the child item inherit all of the permissions of the parent
--     --    item. Typically, this function is called whenever permissions on
--     --    an item are changed for the first time.
--     --    @author Stanislav Freidin
--     --    @param item_id      The item_id
--     --    @param is_recursive If 'f', update child items as well, otherwise
--     --        update only the item itself (note: this is the opposite of
--     --        is_recursive in grant_permission and revoke_permission)
--     --    @see {cms_permission.grant_permission}, {cms_permission.copy_permissions}
--     --*/  
--     item_id           in cr_items.item_id%TYPE,
--     is_recursive      in varchar2 default 't'
--   );
-- 
--   function has_grant_authority (
--     --/** Determine if the user may grant a certain permission to another
--     --    user. The permission may only be granted if the user has 
--     --    the permission himself and posesses the cm_perm access, or if the
--     --    user posesses the cm_perm_admin access.
--     --    @author Stanislav Freidin
--     --    @param item_id     The item whose permissions are to be changed
--     --    @param holder_id   The person who is attempting to grant the permissions
--     --    @param privilege   The privilege to be granted
--     --    @return 't' if the donation is possible, 'f' otherwise
--     --    @see {cms_permission.grant_permission}, 
--     --         {cms_permission.is_has_revoke_authority},
--     --         {acs_permission.grant_permission}
--     --*/
--     item_id           in cr_items.item_id%TYPE,
--     holder_id         in parties.party_id%TYPE, 
--     privilege         in acs_privileges.privilege%TYPE
--   ) return varchar2;
--    
--   procedure grant_permission (
--     --/** Grant the specified privilege to another user. If the donation is
--     --    not possible, the procedure does nothing.
--     --    @author Stanislav Freidin
--     --    @param item_id       The item whose permissions are to be changed
--     --    @param holder_id     The person who is attempting to grant the permissions
--     --    @param privilege     The privilege to be granted
--     --    @param recepient_id  The person who will gain the privilege 
--     --    @param is_recursive  If 't', applies the donation recursively to
--     --      all child items of the item (equivalent to UNIX's <tt>chmod -r</tt>).
--     --      If 'f', only affects the item itself.
--     --    @see {cms_permission.has_grant_authority}, 
--    --          {cms_permission.revoke_permission},
--     --         {acs_permission.grant_permission}
--     --*/
--     item_id           in cr_items.item_id%TYPE,
--     holder_id         in parties.party_id%TYPE,
--     privilege         in acs_privileges.privilege%TYPE,
--     recepient_id      in parties.party_id%TYPE,
--     is_recursive      in varchar2 default 'f'
--   );
-- 
--   function has_revoke_authority (
--     --/** Determine if the user may take a certain permission away from another
--     --    user. The permission may only be revoked if the user has 
--     --    the permission himself and posesses the cm_perm access, while the
--     --    other user does not, or if the user posesses the cm_perm_admin access.
--     --    @author Stanislav Freidin
--     --    @param item_id     The item whose permissions are to be changed
--     --    @param holder_id   The person who is attempting to revoke the permissions
--     --    @param privilege   The privilege to be revoked
--     --    @param revokee_id  The user from whom the privilege is to be taken away
--     --    @return 't' if it is possible to revoke the privilege, 'f' otherwise
--     --    @see {cms_permission.has_grant_authority}, 
--     --         {cms_permission.revoke_permission},
--     --         {acs_permission.revoke_permission}
--     --*/
--     item_id           in cr_items.item_id%TYPE,
--     holder_id         in parties.party_id%TYPE,
--     privilege         in acs_privileges.privilege%TYPE,
--     revokee_id        in parties.party_id%TYPE
--   ) return varchar2;
-- 
--   procedure revoke_permission (
--     --/** Take the specified privilege away from another user. If the operation is
--     --    not possible, the procedure does nothing.
--     --    @author Stanislav Freidin
--     --    @param item_id       The item whose permissions are to be changed
--     --    @param holder_id     The person who is attempting to revoke the permissions
--     --    @param privilege     The privilege to be revoked 
--     --    @param recepient_id  The person who will lose the privilege 
--     --    @param is_recursive  If 't', applies the operation recursively to
--     --      all child items of the item (equivalent to UNIX's <tt>chmod -r</tt>).
--     --      If 'f', only affects the iten itself.
--     --    @see {cms_permission.grant_permission}, 
--     --         {cms_permission.has_revoke_authority},
--     --         {acs_permission.revoke_permission}
--     --*/
--     item_id           in cr_items.item_id%TYPE,
--     holder_id         in parties.party_id%TYPE,
--     privilege         in acs_privileges.privilege%TYPE,
--     revokee_id        in parties.party_id%TYPE,
--     is_recursive      in varchar2 default 'f'
--   );
-- 
--   function permission_p (
--     --/** Determine if the user has the specified permission on the specified 
--     --    object. Does NOT check objects recursively: that is, if the user has
--     --    the permission on the parent object, he does not automatically gain 
--     --    the permission on all the child objects.<p>
--     --    In addition, checks if the Publishing workflow has been assigned to
--     --    the item. If it has, then the user must be assigned to the current 
--     --    workflow task in order to utilize his cm_relate, cm_write or cm_new
--     --    permission.
--     --    @author Stanislav Freidin
--     --    @param item_id       The object whose permissions are to be checked
--     --    @param holder_id     The person whose permissions are to be examined
--     --    @param privilege     The privilege to be checked
--     --    @return 't' if the user has the specified permission on the item, 
--     --                'f' otherwise
--     --    @see {cms_permission.grant_permission}, {cms_permission.revoke_permission},
--     --         {acs_permission.permission_p}
--     --*/
--     item_id           in cr_items.item_id%TYPE,
--     holder_id         in parties.party_id%TYPE,
--     privilege         in acs_privileges.privilege%TYPE
--   ) return varchar2;
-- 
--   function cm_admin_exists 
--     --/** Determine if there exists a user who has administrative 
--     --     privileges on the entire content repository.
--     --     @author Stanislav Freidin
--     --     @return 't' if an administrator exists, 'f' otherwise
--     --     @see {cms_permission.grant_permission}
--     --*/
--   return varchar2;
-- 
-- end cms_permission;

-- show errors

-- FIXME: several routines in this file use custom types that need to be 
-- fixed.


-- create or replace package body cms_permission
-- procedure update_permissions
create or replace function cms_permission__update_permissions (integer,varchar)
returns integer as '
declare
  p_item_id                        alias for $1;  
  p_is_recursive                   alias for $2;  -- default ''f''  
  v_grantee_id                     parties.party_id%TYPE;
  v_privilege                      acs_privileges.privilege%TYPE;
  v_inherit_p                      varchar(1);    
  v_context_id                     acs_objects.context_id%TYPE;
  c_perm_cur                       record;
begin
     
    -- If there is no inheritance, nothing to do
    select security_inherit_p, context_id 
     into v_inherit_p, v_context_id
     from acs_objects
    where object_id = p_item_id;
  
    if v_inherit_p = ''f'' or v_context_id is null then
      return null;
    end if; 

    -- Remove inheritance on the item
    update acs_objects set security_inherit_p = ''f'' 
      where object_id = p_item_id;

    -- If not recursive, turn off inheritance for children of
    -- this item
    if p_is_recursive = ''f'' then
      update 
        acs_objects 
      set
        security_inherit_p = ''f''
      where 
        object_id in (
          select item_id from cr_items 
            where parent_id = p_item_id
        )
      and
        security_inherit_p = ''t'';
    end if;

    -- Get permissions assigned to the parent(s), copy them into child
    -- FIXME: this query needs optimization still

    for c_perm_cur in 
        select 
          p.grantee_id, p.privilege
        from 
          acs_permissions p,
          (select o2.object_id
             from (select * 
                     from acs_objects 
                    where object_id = v_context_id) o1,
                  acs_objects o2,
                  (select ob2.tree_sortkey
                     from (select * 
                             from acs_objects 
                            where object_id = v_context_id) ob1, 
                          acs_objects ob2
                    where ob2.tree_sortkey <= ob1.tree_sortkey
                      and ob1.tree_sortkey between ob2.tree_sortkey and tree_right(ob2.tree_sortkey)
                      and ob2.security_inherit_p = ''f''
                    union
                   select B''0'' as tree_sortkey
                 order by tree_sortkey desc
                          limit 1) o3        
            where o2.tree_sortkey <= o1.tree_sortkey
              and o1.tree_sortkey between o2.tree_sortkey and tree_right(o2.tree_sortkey)
              and o2.tree_sortkey > o3.tree_sortkey
            order by o2.tree_sortkey desc) o
        where  
          p.object_id = o.object_id        
    LOOP
        v_grantee_id := c_perm_cur.grantee_id;
        v_privilege := c_perm_cur.privilege; 
        if acs_permission__permission_p (
             p_item_id, v_grantee_id, v_privilege
           ) = ''f'' 
        then
          PERFORM acs_permission__grant_permission (
            p_item_id, v_grantee_id, v_privilege
          );
        end if;
    end loop;
       
   return 0; 
end;' language 'plpgsql';


-- function has_grant_authority
create or replace function cms_permission__has_grant_authority (integer,integer,varchar)
returns boolean as '
declare
  p_item_id                        alias for $1;  
  p_holder_id                      alias for $2;  
  p_privilege                      alias for $3;  
begin
    -- Can donate permission only if you already have it and you have cm_perm,
    -- OR you have cm_perm_admin
    if acs_permission__permission_p (p_item_id, p_holder_id, ''cm_perm_admin'') = ''t'' 
       or (
         acs_permission__permission_p (p_item_id, p_holder_id, ''cm_perm'') = ''t'' and
         acs_permission__permission_p (p_item_id, p_holder_id, p_privilege) = ''t''
       ) 
    then
      return ''t'';
    else
      return ''f'';
    end if;
   
end;' language 'plpgsql';


-- function has_revoke_authority
create or replace function cms_permission__has_revoke_authority (integer,integer,varchar,integer)
returns boolean as '
declare
  p_item_id                        alias for $1;  
  p_holder_id                      alias for $2;  
  p_privilege                      alias for $3;  
  p_revokee_id                     alias for $4;  
begin
      return  
        count(h2.*) > 0
      from 
        acs_privilege_hierarchy_index h1, 
        acs_privilege_hierarchy_index h2
      where
        acs_permission__permission_p(
          p_item_id, 
          p_holder_id, 
          h2.child_privilege
        ) = ''t''
      and
        acs_permission__permission_p(
          p_item_id, 
          p_revokee_id,
          h2.privilege
        ) = ''f''
      and h1.child_privilege = ''cm_perm''
      and h1.tree_sortkey between h2.tree_sortkey and tree_right(h2.tree_sortkey)
      limit 1;
   
end;' language 'plpgsql';

create table v_items (
       value integer[]
);
insert into v_items (value) values ('{0}');

create or replace function v_items_tr () returns opaque as '
begin
        raise EXCEPTION ''Only updates are allowed on this table'';
        return null;
end;' language 'plpgsql';

create trigger v_items_tr before insert or delete on v_items
for each row execute procedure v_items_tr();


create table v_perms (
       value varchar(100)[]
);
insert into v_perms (value) values ('{''}');

create or replace function v_perms_tr () returns opaque as '
begin
        raise EXCEPTION ''Only updates are allowed on this table'';
        return null;
end;' language 'plpgsql';

create trigger v_perms_tr before insert or delete on v_perms
for each row execute procedure v_perms_tr();

-- procedure grant_permission
-- FIXME: need to fix problem with defined types

create or replace function cms_permission__grant_permission (integer,integer,varchar,integer,varchar)
returns integer as '
declare
  p_item_id                        alias for $1;  
  p_holder_id                      alias for $2;  
  p_privilege                      alias for $3;  
  p_recepient_id                   alias for $4;  
  p_is_recursive                   alias for $5;  -- default ''f''
  v_item_id                        cr_items.item_id%TYPE;
  -- v_items                          item_array_type;
  v_idx                            integer;       
  v_count                          integer;       
  -- v_perms                          perm_array_type;
  v_perm                           acs_privileges.privilege%TYPE;
  v_perm_idx                       integer;       
  v_perm_count                     integer;       
  c_item_cur                       record;
  c_perm_cur                       record;
begin

    PERFORM cms_permission__update_permissions(p_item_id, p_is_recursive);
  
    -- Select all child items
    v_count := 0;

    for c_item_cur in 
      select 
        item_id 
      from 
        (select c1.item_id from cr_items c1, cr_items c2
         where c2.item_id = p_item_id
           and c1.tree_sortkey between c2.tree_sortkey and tree_right(c2.tree_sortkey)
         order by c1.tree_sortkey) i
      where
        cms_permission__has_grant_authority (
          i.item_id, p_holder_id, p_privilege
        ) = ''t''
      and 
        acs_permission__permission_p (
          i.item_id, p_recepient_id, p_privilege
        ) = ''f''
    LOOP
      v_item_id := c_item_cur.item_id;
      v_count := v_count + 1;
      -- v_items(v_count) := v_item_id;
      update v_items set value[v_count] = v_item_id;
      exit when p_is_recursive = ''f'';
    end loop;

    if v_count < 1 then 
      return null;
    end if;

    -- Grant parent permission
    for v_idx in 1..v_count loop
      PERFORM acs_permission__grant_permission (
        -- v_items(v_idx), p_recepient_id, p_privilege
        v_items.value[v_idx], p_recepient_id, p_privilege
      );
    end loop;  

    -- Select the child permissions
    v_perm_count := 0;
    for c_perm_cur in 
      select descendant from acs_privilege_descendant_map
      where privilege = p_privilege
      and   descendant <> p_privilege
    loop
      v_perm := c_perm_cur.descendant;
      v_perm_count := v_perm_count + 1;
      -- v_perms(v_perm_count) := v_perm;
      update v_perms set value[v_perm_count] = v_perm;
    end loop;

    -- Revoke child permissions
    for v_idx in 1..v_count loop
      for v_perm_idx in 1..v_perm_count loop
        PERFORM acs_permission__revoke_permission (
          -- v_items(v_idx), p_recepient_id, v_perms(v_perm_idx)
          v_items.value[v_idx], p_recepient_id, v_perms.value[v_perm_idx]
        );
       end loop;
    end loop;
  
    return 0; 
end;' language 'plpgsql';


-- procedure revoke_permission
create or replace function cms_permission__revoke_permission (integer,integer,varchar,integer,varchar)
returns integer as '
declare
  p_item_id                        alias for $1;  
  p_holder_id                      alias for $2;  
  p_privilege                      alias for $3;  
  p_revokee_id                     alias for $4;  
  p_is_recursive                   alias for $5;  -- default ''f''
  -- v_items                          item_array_type;
  v_item_id                        cr_items.item_id%TYPE;
  v_idx                            integer;       
  v_count                          integer;       
  -- v_perms                          perm_array_type;
  v_perm                           acs_privileges.privilege%TYPE;
  v_perm_idx                       integer;       
  v_perm_count                     integer;       
  c_perm_cur                       record;
  c_item_cur                       record;
begin
  
    PERFORM update_permissions(p_item_id, p_is_recursive);

    -- Select the child permissions
    v_perm_count := 0;
    for c_perm_cur in 
     select
        child_privilege
      from 
        acs_privilege_hierarchy
      where 
        privilege = p_privilege
      and 
        child_privilege <> p_privilege
    LOOP
      v_perm := c_perm_cur.child_privilege;
      v_perm_count := v_perm_count + 1;
      -- v_perms(v_perm_count) := v_perm;
      update v_perms set value[v_perm_count] = v_perm;
    end LOOP;

    -- Select child items 
    v_count := 0;
    for c_item_cur in
     select c1.item_id from cr_items c1, cr_items c2
     where c2.item_id = p_item_id
       and c1.tree_sortkey between c2.tree_sortkey and tree_right(c2.tree_sortkey)
      and
        cms_permission__has_revoke_authority (
          item_id, 
          p_holder_id,
          p_privilege,
          p_revokee_id
        ) = ''t''
      and
        acs_permission__permission_p (
          item_id,
          p_revokee_id,
          p_privilege
        ) = ''t''
    LOOP
      v_item_id := c_item_cur.item_id;
      v_count := v_count + 1;
      -- v_items(v_count) := v_item_id;
      update v_items set value[v_count] = v_item_id;
      exit when p_is_recursive = ''f'';
    end loop;

    if v_count < 1 then 
      return;
    end if;

    -- Grant child permissions
    for v_idx in 1..v_count loop
      for v_perm_idx in 1..v_perm_count loop
        PERFORM acs_permission__grant_permission (
          -- v_items(v_idx), p_revokee_id, v_perms(v_perm_idx)
          v_items.value[v_idx], p_revokee_id, v_perms.value[v_perm_idx]
        );
       end loop;
    end loop;  

    -- Revoke the parent permission
    for v_idx in 1..v_count loop
      PERFORM acs_permission__revoke_permission (
        -- v_items(v_idx), 
        v_items.value[v_idx],
        p_revokee_id, 
        p_privilege
      );
    end loop;  

    return 0; 
end;' language 'plpgsql';


-- function permission_p
create or replace function cms_permission__permission_p (integer,integer,varchar)
returns boolean as '
declare
  p_item_id                        alias for $1;  
  p_holder_id                      alias for $2;  
  p_privilege                      alias for $3;  
  v_workflow_count                 integer;       
  v_task_count                     integer;       
begin
      
    -- Check permission the old-fashioned way first
    if acs_permission__permission_p (
         p_item_id, p_holder_id, p_privilege
       ) = ''f'' 
    then
      return ''f'';
    end if;
  
    -- Special case for workflow

    if p_privilege = ''cm_relate'' or 
       p_privilege = ''cm_write'' or 
       p_privilege = ''cm_new'' 
    then

      -- Check if the publishing workflow exists, and if it
      -- is the only workflow that exists
      select
        count(case_id) into v_workflow_count
      from
        wf_cases
      where
        object_id = p_item_id;

      -- If there are multiple workflows / no workflows, do nothing
      -- special
      if v_workflow_count <> 1 then
        return ''t'';
      end if;       
        
      -- Even if there is a workflow, the user can touch the item if he
      -- has cm_item_workflow
      if acs_permission__permission_p (
         p_item_id, p_holder_id, ''cm_item_workflow''
       ) = ''t'' 
      then
        return ''t'';
      end if;

      -- Check if the user holds the current task
      if v_workflow_count = 0 then
	return ''f'';
      end if;

      select
	count(task_id) into v_task_count
      from
	wf_user_tasks t, wf_cases c
      where
	t.case_id = c.case_id
      and
	c.workflow_key = ''publishing_wf''
      and
	c.state = ''active''
      and
	c.object_id = p_item_id
      and
	( t.state = ''enabled'' 
	  or 
	    ( t.state = ''started'' and t.holding_user = p_holder_id ))
      and
	t.user_id = p_holder_id;

      -- is the user assigned a current task on this item
      if v_task_count = 0 then
	return ''f'';
      end if;      

    end if;

    return ''t'';
    
end;' language 'plpgsql';

create or replace function cms_permission__cm_admin_exists() returns boolean as '
declare
    v_exists    boolean;
begin
    
    select ''t'' into v_exists from dual 
     where exists (
       select 1 from acs_permissions 
       where privilege in (''cm_admin'', ''cm_root'')
     );

     if NOT FOUND then 
        return ''f'';
     else 
        return ''t'';
     end if;

end;' language 'plpgsql';


-- show errors

-- A trigger to automatically grant item creators the cm_write and cm_perm
-- permissions

create or replace function cr_items_permission_tr () returns opaque as '
declare
  v_user_id parties.party_id%TYPE;
begin
  
  select creation_user into v_user_id from acs_objects
    where object_id = new.item_id;

  -- FIXME: check to see if this is correct.

  if NOT FOUND then 
     return null;
  end if;

  if v_user_id is not null then

    if acs_permission__permission_p (
        new.item_id, v_user_id, ''cm_write''
       ) = ''f'' 
    then
      perform acs_permission__grant_permission (
        new.item_id, v_user_id, ''cm_write''
      );
    end if;
  
    if acs_permission__permission_p (
        new.item_id, v_user_id, ''cm_perm''
       ) = ''f'' 
    then
      perform acs_permission__grant_permission (
        new.item_id, v_user_id, ''cm_perm''
      );
    end if; 
  end if;

-- exception when no_data_found then null;
   
  return new;
end;' language 'plpgsql';

create trigger cr_items_permission_tr after insert on cr_items
for each row execute procedure cr_items_permission_tr ();

-- show errors
         
        
-- A simple wrapper for acs-content-repository procs   
    
-- create or replace package content_permission 
-- is
-- 
--   procedure inherit_permissions (
--     parent_object_id  in acs_objects.object_id%TYPE,
--     child_object_id   in acs_objects.object_id%TYPE,
--     child_creator_id  in parties.party_id%TYPE default null
--   );
-- 
--   function has_grant_authority (
--     object_id         in acs_objects.object_id%TYPE,
--     holder_id         in parties.party_id%TYPE, 
--     privilege         in acs_privileges.privilege%TYPE
--   ) return varchar2;
--    
--   procedure grant_permission_h (
--     object_id         in acs_objects.object_id%TYPE,
--     grantee_id        in parties.party_id%TYPE,
--     privilege         in acs_privileges.privilege%TYPE
--   );
-- 
--   procedure grant_permission (
--     object_id         in acs_objects.object_id%TYPE,
--     holder_id         in parties.party_id%TYPE,
--     privilege         in acs_privileges.privilege%TYPE,
--     recepient_id      in parties.party_id%TYPE,
--     is_recursive      in varchar2 default 'f',
--     object_type       in acs_objects.object_type%TYPE default 'content_item'
--   );
-- 
--   function has_revoke_authority (
--     object_id         in acs_objects.object_id%TYPE,
--     holder_id         in parties.party_id%TYPE,
--     privilege         in acs_privileges.privilege%TYPE,
--     revokee_id        in parties.party_id%TYPE
--   ) return varchar2;
-- 
--   procedure revoke_permission_h (
--     object_id         in acs_objects.object_id%TYPE,
--     revokee_id        in parties.party_id%TYPE,
--     privilege         in acs_privileges.privilege%TYPE
--   );
-- 
--   procedure revoke_permission (
--     object_id         in acs_objects.object_id%TYPE,
--     holder_id         in parties.party_id%TYPE,
--     privilege         in acs_privileges.privilege%TYPE,
--     revokee_id        in parties.party_id%TYPE,
--     is_recursive      in varchar2 default 'f',
--     object_type       in acs_objects.object_type%TYPE default 'content_item'
--   );
-- 
--   function permission_p (
--     object_id         in acs_objects.object_id%TYPE,
--     holder_id         in parties.party_id%TYPE,
--     privilege         in acs_privileges.privilege%TYPE
--   ) return varchar2;
-- 
--   function cm_admin_exists 
--   return varchar2;
-- 
-- end content_permission;

-- show errors


-- create or replace package body content_permission 
-- procedure inherit_permissions
create or replace function content_permission__inherit_permissions (integer,integer,integer)
returns integer as '
declare
  p_parent_object_id               alias for $1;  
  p_child_object_id                alias for $2;  
  p_child_creator_id               alias for $3;  -- default null  
begin
    PERFORM cms_permission__update_permissions(p_child_object_id);
    return 0; 
end;' language 'plpgsql';


-- function has_grant_authority
create or replace function content_permission__has_grant_authority (integer,integer,varchar)
returns boolean as '
declare
  p_object_id                      alias for $1;  
  p_holder_id                      alias for $2;  
  p_privilege                      alias for $3;  
begin
    return cms_permission__has_grant_authority (
      p_object_id, p_holder_id, p_privilege
    );
   
end;' language 'plpgsql';


-- procedure grant_permission_h
create or replace function content_permission__grant_permission_h (integer,integer,varchar)
returns integer as '
declare
  p_object_id                      alias for $1;  
  p_grantee_id                     alias for $2;  
  p_privilege                      alias for $3;  
begin
  return 0; 
end;' language 'plpgsql';


-- procedure grant_permission
create or replace function content_permission__grant_permission (integer,integer,varchar,integer,varchar,varchar)
returns integer as '
declare
  p_object_id                      alias for $1;  
  p_holder_id                      alias for $2;  
  p_privilege                      alias for $3;  
  p_recepient_id                   alias for $4;  
  p_is_recursive                   alias for $5;  -- default ''f''
  p_object_type                    alias for $6;  -- default ''content_item''
begin
    PERFORM cms_permission__grant_permission (
      p_object_id, p_holder_id, p_privilege, p_recepient_id, p_is_recursive
    );

    return 0; 
end;' language 'plpgsql';


-- function has_revoke_authority
create or replace function content_permission__has_revoke_authority (integer,integer,varchar,integer)
returns boolean as '
declare
  p_object_id                      alias for $1;  
  p_holder_id                      alias for $2;  
  p_privilege                      alias for $3;  
  p_revokee_id                     alias for $4;  
begin
    return cms_permission__has_revoke_authority (
      p_object_id, p_holder_id, p_privilege, p_revokee_id
    );
   
end;' language 'plpgsql';


-- procedure revoke_permission_h
create or replace function content_permission__revoke_permission_h (integer,integer,varchar)
returns integer as '
declare
  p_object_id                      alias for $1;  
  p_revokee_id                     alias for $2;  
  p_privilege                      alias for $3;  
begin
  return 0; 
end;' language 'plpgsql';


-- procedure revoke_permission
create or replace function content_permission__revoke_permission (integer,integer,varchar,integer,varchar,varchar)
returns integer as '
declare
  p_object_id                      alias for $1;  
  p_holder_id                      alias for $2;  
  p_privilege                      alias for $3;  
  p_revokee_id                     alias for $4;  
  p_is_recursive                   alias for $5;  -- default ''f''  
  p_object_type                    alias for $6;  -- default ''content_item''
begin
    PERFORM cms_permission__revoke_permission (
      p_object_id, p_holder_id, p_privilege, p_revokee_id, p_is_recursive
    );

    return 0; 
end;' language 'plpgsql';


-- function permission_p
create or replace function content_permission__permission_p (integer,integer,varchar)
returns boolean as '
declare
  p_object_id                      alias for $1;  
  p_holder_id                      alias for $2;  
  p_privilege                      alias for $3;  
begin
    return cms_permission__permission_p (
      p_object_id, p_holder_id, p_privilege
    );
   
end;' language 'plpgsql';



-- show errors
      









