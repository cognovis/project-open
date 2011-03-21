-- upgrade-4.5.0-4.5.1.sql



-- Add a new column to determine that both panels should be overwritten
create or replace function inline_0 ()
returns integer as '
declare
        v_count                 integer;
begin
        select  count(*)
        into    v_count
        from    user_tab_columns
        where   lower(table_name) = ''wf_context_task_panels''
                and lower(column_name) = ''overrides_both_panels_p'';

        if v_count = 1 then
            return 0;
        end if;

	alter table wf_context_task_panels
	add overrides_both_panels_p char(1)
	constraint wf_context_panels_ovrd_both_ck
	CHECK (overrides_both_panels_p = ''t'' OR overrides_both_panels_p = ''f'');

	alter table wf_context_task_panels
	alter column overrides_both_panels_p set default ''f'';

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();





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

        IF add_task_assignment__permanent_p = ''t'' and v_role_key is not null THEN
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

