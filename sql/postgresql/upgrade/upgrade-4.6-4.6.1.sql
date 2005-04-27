-- DRB: None of this code has changed.  We need to redefine these items because
-- the party_approved_member_map is now a table rather than view

drop view wf_user_tasks;
create view wf_user_tasks as
select distinct ta.task_id, 
       ta.case_id, 
       ta.workflow_key,
       ta.transition_key, 
       tr.transition_name, 
       ta.enabled_date, 
       ta.started_date, 
       u.user_id, 
       ta.state, 
       ta.holding_user, 
       ta.hold_timeout,
       ta.deadline,
       ta.estimated_minutes
from   wf_tasks ta,
       wf_task_assignments tasgn,
       wf_cases c,
       wf_transition_info tr,
       party_approved_member_map m,
       users u
where  ta.state in ( 'enabled','started')
and    c.case_id = ta.case_id
and    c.state = 'active'
and    tr.transition_key = ta.transition_key
and    tr.workflow_key = ta.workflow_key
and    tr.trigger_type = 'user'
and    tr.context_key = c.context_key
and    tasgn.task_id = ta.task_id
and    m.party_id = tasgn.party_id
and    u.user_id = m.member_id;

-- procedure add_task_assignment
create or replace function workflow_case__add_task_assignment (integer,integer,boolean)
returns integer as '
declare
  add_task_assignment__task_id                alias for $1;  
  add_task_assignment__party_id               alias for $2;  
  add_task_assignment__permanent_p	      alias for $3;
  v_count                                    integer;       
  v_workflow_key                             wf_workflows.workflow_key%TYPE;
  v_context_key                              wf_contexts.context_key%TYPE;
  v_case_id                                  wf_cases.case_id%TYPE;
  v_role_key				     wf_roles.role_key%TYPE;
  v_transition_key                           wf_transitions.transition_key%TYPE;
  v_notification_callback     wf_context_transition_info.notification_callback%TYPE;
  v_notification_custom_arg   wf_context_transition_info.notification_custom_arg%TYPE;
  callback_rec                record;
  v_assigned_user             record;
begin
        -- get some needed information

        select ta.case_id, ta.workflow_key, ta.transition_key, tr.role_key, c.context_key
        into   v_case_id, v_workflow_key, v_transition_key, v_role_key, v_context_key
        from   wf_tasks ta, wf_transitions tr, wf_cases c
        where  ta.task_id = add_task_assignment__task_id
          and  tr.workflow_key = ta.workflow_key
          and  tr.transition_key = ta.transition_key
          and  c.case_id = ta.case_id;

        -- make the same assignment as a manual assignment

        if add_task_assignment__permanent_p = ''t'' then
	    /* We do this up-front, because 
	     * even though the user already had a task assignment, 
	     * he might not have a case assignment.
	     */
            perform workflow_case__add_manual_assignment (
                v_case_id,
                v_role_key,
                add_task_assignment__party_id
            );
        end if;

        -- check that we do not hit the unique constraint

        select count(*) into v_count
        from   wf_task_assignments
        where  task_id = add_task_assignment__task_id
        and    party_id = add_task_assignment__party_id;

        if v_count > 0 then
            return null;
        end if;

        -- get callback information

        select notification_callback,
		   notification_custom_arg into callback_rec
	    from   wf_context_transition_info
	    where  context_key = v_context_key
	    and    workflow_key = v_workflow_key
	    and    transition_key = v_transition_key;

            
        if FOUND then
            v_notification_callback := callback_rec.notification_callback;
            v_notification_custom_arg := callback_rec.notification_custom_arg;
        else
            v_notification_callback := null;
            v_notification_custom_arg := null;
        end if;

        -- notify any new assignees

        for v_assigned_user in  
            select distinct u.user_id
            from   users u
            where  u.user_id not in (
	            select distinct u2.user_id
	            from   wf_task_assignments tasgn2,
	                   party_approved_member_map m2,
	                   users u2
	            where  tasgn2.task_id = add_task_assignment__task_id
	            and    m2.party_id = tasgn2.party_id
	            and    u2.user_id = m2.member_id)
            and exists (
                select 1 
                from   party_approved_member_map m
                where  m.member_id = u.user_id
                and    m.party_id = add_task_assignment__party_id
            )
        LOOP
            PERFORM workflow_case__notify_assignee (
                add_task_assignment__task_id,
                v_assigned_user.user_id,
                v_notification_callback,
                v_notification_custom_arg
            );
        end loop;

        -- do the insert

        insert into wf_task_assignments (
            task_id, 
            party_id
        ) values (
            add_task_assignment__task_id, 
            add_task_assignment__party_id
        );

        return 0; 
end;' language 'plpgsql';

-- function begin_task_action
create or replace function workflow_case__begin_task_action (integer,varchar,varchar,integer,varchar)
returns integer as '
declare
  begin_task_action__task_id                alias for $1;  
  begin_task_action__action                 alias for $2;  
  begin_task_action__action_ip              alias for $3;  
  begin_task_action__user_id                alias for $4;  
  begin_task_action__msg                    alias for $5;  -- default null  
  v_state                                   varchar;
  v_journal_id                              integer;
  v_case_id                                 integer;
  v_transition_name                         varchar;
  v_num_rows                                integer;
begin
        select state into v_state
        from   wf_tasks
        where  task_id = begin_task_action__task_id;

        if begin_task_action__action = ''start'' then
            if v_state != ''enabled'' then
                raise EXCEPTION ''-20000: Task is in state "%", but it must be in state "enabled" to be started.'', v_state;
            end if;
        
            select case when count(*) = 0 then 0 else 1 end into v_num_rows
            from   wf_user_tasks
            where  task_id = begin_task_action__task_id
            and    user_id = begin_task_action__user_id;
            
            if v_num_rows = 0 then
                raise EXCEPTION ''-20000: You are not assigned to this task.'';
            end if;
        else if begin_task_action__action = ''finish'' or begin_task_action__action = ''cancel'' then

            if v_state = ''started'' then
                /* Is this user the holding user? */
                select case when count(*) = 0 then 0 else 1 end into v_num_rows
                from   wf_tasks
                where  task_id = begin_task_action__task_id
                and    holding_user = begin_task_action__user_id;
                if v_num_rows = 0 then  
                    raise EXCEPTION ''-20000: You are not the user currently working on this task.'';
                end if;
            else if v_state = ''enabled'' then
                if begin_task_action__action = ''cancel'' then
                    raise EXCEPTION ''-20000: You can only cancel a task in state "started", but this task is in state "%"'', v_state;
                end if;

                /* Is this user assigned to this task? */
                select case when count(*) = 0 then 0 else 1 end into v_num_rows
                from   wf_user_tasks
                where  task_id = begin_task_action__task_id
                and    user_id = begin_task_action__user_id;
                if v_num_rows = 0 then  
                    raise EXCEPTION ''-20000: You are not assigned to this task.'';
                end if;

                /* This task is finished without an explicit start.
                 * Store the user as the holding_user */
                update wf_tasks 
                set    holding_user = begin_task_action__user_id 
                where  task_id = begin_task_action__task_id;
            else
                raise EXCEPTION ''-20000: Task is in state "%", but it must be in state "enabled" or "started" to be finished'', v_state;
            end if; end if;

        else if begin_task_action__action = ''comment'' then
            -- We currently allow anyone to comment on a task
            -- (need this line because PL/SQL does not like empty if blocks)
            v_num_rows := 0;
        end if; end if; end if;

        select  t.case_id, tr.transition_name into v_case_id, v_transition_name
        from    wf_tasks t, 
                wf_transitions tr
        where   t.task_id = begin_task_action__task_id
        and     tr.workflow_key = t.workflow_key
        and     tr.transition_key = t.transition_key;

        /* Insert a journal entry */

        v_journal_id := journal_entry__new (
            null,
            v_case_id,
            ''task '' || begin_task_action__task_id || '' '' || begin_task_action__action,
            v_transition_name || '' '' || begin_task_action__action,
            now(),
            begin_task_action__user_id,
            begin_task_action__action_ip,
            begin_task_action__msg
        );

        return v_journal_id;
     
end;' language 'plpgsql';

