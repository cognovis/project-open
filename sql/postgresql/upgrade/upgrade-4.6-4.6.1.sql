-- DRB: Needed because workflow views were dependent on the party_approved_member_map
-- view (which is now a table) and because PG doesn't support CREATE OR REPLACE VIEW.

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

-- function can_touch
create or replace function content_workflow__can_touch (integer,integer)
returns boolean as '
declare
  p_item_id                        alias for $1;  
  p_user_id                        alias for $2;  
  v_workflow_count                 integer;       
  v_task_count                     integer;       
begin

    -- cm_admin has highest precedence
    if content_permission__permission_p( 
      p_item_id, p_user_id, ''cm_item_workflow'' ) = ''t'' then
      return ''t'';
    end if;

    select
      count(case_id) into v_workflow_count
    from
      wf_cases
    where
      object_id = p_item_id;

    -- workflow must exist
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
          ( t.state = ''started'' and t.holding_user = p_user_id ))
    and
      t.user_id = p_user_id;


    -- is the user assigned a current task on this item
    if v_task_count = 0 then
      return ''f'';
    else
      return ''t'';
    end if;

   
end;' language 'plpgsql';

