-- create or replace package body workflow_case
-- function new

create or replace function workflow_case__new (integer,varchar,varchar,integer,timestamptz,integer,varchar)
returns integer as '
declare
  new__case_id                alias for $1;  -- default null  
  new__workflow_key           alias for $2;  
  new__context_key            alias for $3;  -- default null
  new__object_id              alias for $4;  
  new__creation_date          alias for $5;  -- default now()
  new__creation_user          alias for $6;  -- default null
  new__creation_ip            alias for $7;  -- default null
  v_case_id                   integer;
  v_workflow_case_table       varchar;
  v_context_key_for_query     varchar;
begin
        if new__context_key = '''' or new__context_key is null then
            v_context_key_for_query := ''default'';
        else
            v_context_key_for_query := new__context_key;
        end if;

        /* insert a row into acs_objects */
        v_case_id := acs_object__new(
            new__case_id,
            new__workflow_key,
            new__creation_date,
            new__creation_user,
            new__creation_ip,
            null
        );

        /* insert the case in to the general wf_cases table */
        insert into wf_cases 
            (case_id, workflow_key, context_key, object_id, state)
        values 
            (v_case_id, new__workflow_key, v_context_key_for_query, new__object_id, ''created'');
            
        /* insert the case into the workflow-specific cases table */
        select table_name into v_workflow_case_table
        from   acs_object_types
        where  object_type = new__workflow_key;

        execute ''insert into '' || v_workflow_case_table || '' (case_id) values ('' || v_case_id || '')'';

        return v_case_id;
     
end;' language 'plpgsql';


-- procedure add_manual_assignment
create or replace function workflow_case__add_manual_assignment (integer,varchar,integer)
returns integer as '
declare
  add_manual_assignment__case_id                alias for $1;  
  add_manual_assignment__role_key		alias for $2;  
  add_manual_assignment__party_id               alias for $3;  
  v_workflow_key                                varchar;  
  v_num_rows					integer;
begin
        select count(*)
          into v_num_rows
          from wf_case_assignments
         where case_id = add_manual_assignment__case_id
           and role_key = add_manual_assignment__role_key
           and party_id = add_manual_assignment__party_id;

        if v_num_rows = 0 then
	    select workflow_key 
	      into v_workflow_key 
	      from wf_cases 
	     where case_id = add_manual_assignment__case_id;
        
            insert into wf_case_assignments (
                case_id, 
                workflow_key, 
                role_key, 
                party_id
            ) values (
                add_manual_assignment__case_id, 
                v_workflow_key, 
                add_manual_assignment__role_key, 
                add_manual_assignment__party_id
            );
        end if;

        return 0; 
end;' language 'plpgsql';


-- procedure remove_manual_assignment
create or replace function workflow_case__remove_manual_assignment (integer,varchar,integer)
returns integer as '
declare
  remove_manual_assignment__case_id                alias for $1;  
  remove_manual_assignment__role_key		   alias for $2;  
  remove_manual_assignment__party_id               alias for $3;  
  v_workflow_key				   varchar;
begin
        select workflow_key 
          into v_workflow_key 
          from wf_cases
         where case_id = remove_manual_assignment__case_id;
        
        delete 
          from wf_case_assignments
         where workflow_key = v_workflow_key
           and case_id = remove_manual_assignment__case_id
           and role_key = remove_manual_assignment__role_key
           and party_id = remove_manual_assignment__party_id;

  return 0; 
end;' language 'plpgsql';


-- procedure clear_manual_assignments
create or replace function workflow_case__clear_manual_assignments (integer,varchar)
returns integer as '
declare
  clear_manual_assignments__case_id                alias for $1;  
  clear_manual_assignments__role_key		   alias for $2;  
  v_workflow_key				   varchar;
begin
        select workflow_key 
          into v_workflow_key
          from wf_cases 
         where case_id = clear_manual_assignments__case_id;
        
        delete 
          from wf_case_assignments 
         where workflow_key = v_workflow_key 
           and case_id = clear_manual_assignments__case_id
           and role_key = clear_manual_assignments__role_key;
   return 0; 
end;' language 'plpgsql';


-- procedure start_case
create or replace function workflow_case__start_case (integer,integer,varchar,varchar)
returns integer as '
declare
  start_case__case_id                alias for $1;  
  start_case__creation_user          alias for $2;  -- default null  
  start_case__creation_ip            alias for $3;  -- default null
  start_case__msg                    alias for $4;  -- default null
  v_journal_id                       integer;        
begin
        /* Add an entry to the journal */
        v_journal_id := journal_entry__new(
            null, 
            start_case__case_id,
            ''case start'',
            ''Case started'',
            now(),
            start_case__creation_user,
            start_case__creation_ip,
            start_case__msg
        );

        update wf_cases 
           set state = ''active'' 
         where case_id = start_case__case_id;

        PERFORM workflow_case__add_token (
            start_case__case_id, 
            ''start'',
            v_journal_id
        );

        -- Turn the wheels
        PERFORM workflow_case__sweep_automatic_transitions (
            start_case__case_id,
            v_journal_id
        );

        return 0; 
end;' language 'plpgsql';


-- procedure delete
create or replace function workflow_case__delete (integer)
returns integer as '
declare
  delete__case_id                alias for $1;  
  v_workflow_case_table          varchar;   
begin
        /* delete attribute_value_audit, tokens, tasks  */
        delete from wf_attribute_value_audit 
         where case_id = delete__case_id;

        delete from wf_case_assignments 
         where case_id = delete__case_id;

        delete from wf_case_deadlines 
         where case_id = delete__case_id;

        delete from wf_tokens 
         where case_id = delete__case_id;

        delete from wf_task_assignments 
         where task_id in (select task_id 
                             from wf_tasks 
                            where case_id = delete__case_id);

        delete from wf_tasks 
         where case_id = delete__case_id;

        /* delete the journal */
        PERFORM journal_entry__delete_for_object(delete__case_id);
        
        /* delete from the workflow-specific cases table */
        select table_name into v_workflow_case_table
        from   acs_object_types ot, wf_cases c
        where  c.case_id = delete__case_id
        and    object_type = c.workflow_key;
        
        execute ''delete from '' || v_workflow_case_table || '' where case_id = '' || delete__case_id;

        /* delete from the generic cases table */
        delete from wf_cases where case_id = delete__case_id;

        /* delete from acs-objects */
        PERFORM acs_object__delete(delete__case_id);

        return 0; 
end;' language 'plpgsql';


-- procedure suspend
create or replace function workflow_case__suspend (integer,integer,varchar,varchar)
returns integer as '
declare
  suspend__case_id                alias for $1;  
  suspend__user_id                alias for $2;  -- default null  
  suspend__ip_address             alias for $3;  -- default null
  suspend__msg                    alias for $4;  -- default null
  v_state                         varchar;   
  v_journal_id                    integer;        
begin
        select state into v_state
        from   wf_cases
        where  case_id = suspend__case_id;

        if v_state != ''active'' then
            raise EXCEPTION ''-20000: Only active cases can be suspended'';
        end if;
        
        /* Add an entry to the journal */
        v_journal_id := journal_entry__new(
            null,
            suspend__case_id,
            ''case suspend'',
            ''case suspended'',
            now(),
            suspend__user_id,
            suspend__ip_address,
            suspend__msg
        );

        update wf_cases
        set    state = ''suspended''
        where  case_id = suspend__case_id;

        return 0; 
end;' language 'plpgsql';


-- procedure resume
create or replace function workflow_case__resume (integer,integer,varchar,varchar)
returns integer as '
declare
  resume__case_id                alias for $1;  
  resume__user_id                alias for $2;  -- default null  
  resume__ip_address             alias for $3;  -- default null
  resume__msg                    alias for $4;  -- default null
  v_state                        varchar;   
  v_journal_id                   integer;        
begin
        select state into v_state
        from   wf_cases
        where  case_id = resume__case_id;

        if v_state != ''suspended'' and v_state != ''canceled'' then
            raise EXCEPTION ''-20000: Only suspended or canceled cases can be resumed'';
        end if;

        /* Add an entry to the journal */
        v_journal_id := journal_entry__new(
            null,
            resume__case_id,
            ''case resume'',
            ''case resumed'',
            now(),
            resume__user_id,
            resume__ip_address,
            resume__msg
        );

        update wf_cases
        set    state = ''active''
        where  case_id = resume__case_id;

        return 0; 
end;' language 'plpgsql';


-- procedure cancel
create or replace function workflow_case__cancel (integer,integer,varchar,varchar)
returns integer as '
declare
  cancel__case_id                alias for $1;  
  cancel__user_id                alias for $2;  -- default null  
  cancel__ip_address             alias for $3;  -- default null
  cancel__msg                    alias for $4;  -- default null
  v_state                        varchar;   
  v_journal_id                   integer;        
begin
        select state into v_state
        from   wf_cases
        where  case_id = cancel__case_id;

        if v_state != ''active'' and v_state != ''suspended'' then
            raise EXCEPTION ''-20000: Only active or suspended cases can be canceled'';
        end if;

        /* Add an entry to the journal */
        v_journal_id := journal_entry__new(
            null,
            cancel__case_id,
            ''case cancel'',
            ''Case canceled'',
            now(),
            cancel__user_id,
            cancel__ip_address,
            cancel__msg
        );

        update wf_cases
        set    state = ''canceled''
        where  case_id = cancel__case_id;

        return 0; 
end;' language 'plpgsql';


-- procedure fire_message_transition
create or replace function workflow_case__fire_message_transition (integer)
returns integer as '
declare
  fire_message_transition__task_id               alias for $1;  
  v_case_id                                      integer;        
  v_transition_name                              varchar;  
  v_trigger_type                                 varchar;   
  v_journal_id                                   integer;        
begin
        select t.case_id, tr.transition_name, tr.trigger_type 
        into   v_case_id, v_transition_name, v_trigger_type
        from   wf_tasks t, wf_transitions tr
        where  t.task_id = fire_message_transition__task_id
        and    tr.workflow_key = t.workflow_key
        and    tr.transition_key = t.transition_key;

        if v_trigger_type != ''message'' then
	    raise EXCEPTION ''-20000: Transition "%" is not message triggered'',  v_transition_name;
        end if;

        /* Add an entry to the journal */
        v_journal_id := journal_entry__new (
            null,
            v_case_id,
            ''task '' || fire_message_transition__task_id || '' fire'',
            v_transition_name || '' fired'',
            now(),
            null,
            null,
            null
        );
        
        PERFORM workflow_case__fire_transition_internal(
            fire_message_transition__task_id,
            v_journal_id
        );

        PERFORM workflow_case__sweep_automatic_transitions (
            v_case_id,
            v_journal_id
        );

        return 0; 
end;' language 'plpgsql';


    /*
     * A wrapper for user tasks that uses the start/commit/cancel model for firing transitions.
     * Returns journal_id.
     */
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


-- procedure end_task_action
create or replace function workflow_case__end_task_action (integer,varchar,integer)
returns integer as '
declare
  end_task_action__journal_id             alias for $1;  
  end_task_action__action                 alias for $2;  
  end_task_action__task_id                alias for $3;  
  v_user_id                               integer;
begin
        select creation_user into v_user_id
        from   acs_objects
        where  object_id = end_task_action__journal_id;

        /* Update the workflow state */

        if end_task_action__action = ''start'' then
            PERFORM workflow_case__start_task(end_task_action__task_id, 
                                              v_user_id, 
                                              end_task_action__journal_id
                    );
        else if end_task_action__action = ''finish'' then
            PERFORM workflow_case__finish_task(end_task_action__task_id, 
                                               end_task_action__journal_id
                    );
        else if end_task_action__action = ''cancel'' then
            PERFORM workflow_case__cancel_task(end_task_action__task_id, 
                                               end_task_action__journal_id
                    );
        else if end_task_action__action != ''comment'' then
            raise EXCEPTION ''-20000: Unknown action "%"'', end_task_action__action;
        end if; end if; end if; end if;

        return 0; 
end;' language 'plpgsql';


-- function task_action
create or replace function workflow_case__task_action (integer,varchar,varchar,integer,varchar)
returns integer as '
declare
  task_action__task_id                alias for $1;  
  task_action__action                 alias for $2;  
  task_action__action_ip              alias for $3;  
  task_action__user_id                alias for $4;  
  task_action__msg                    alias for $5;  -- default null  
  v_journal_id                        integer;       
begin
        v_journal_id := workflow_case__begin_task_action (
            task_action__task_id,
            task_action__action,
            task_action__action_ip,
            task_action__user_id,
            task_action__msg
        );
        
        PERFORM workflow_case__end_task_action (
            v_journal_id,
            task_action__action,
            task_action__task_id
        );

        return v_journal_id;        
     
end;' language 'plpgsql';


-- procedure set_attribute_value
create or replace function workflow_case__set_attribute_value (integer,varchar,varchar)
returns integer as '
declare
  set_attribute_value__journal_id             alias for $1;  
  set_attribute_value__attribute_name         alias for $2;  
  set_attribute_value__value                  alias for $3;  
  v_workflow_key                              varchar;
  v_case_id                                   integer;
  v_attribute_id                              integer;
begin
        select o.object_type, o.object_id into v_workflow_key, v_case_id
        from   journal_entries je, acs_objects o
        where  je.journal_id = set_attribute_value__journal_id
        and    o.object_id = je.object_id;
        
        select attribute_id into v_attribute_id
        from acs_attributes
        where object_type = v_workflow_key
        and   attribute_name = set_attribute_value__attribute_name;
        
        PERFORM acs_object__set_attribute (
            v_case_id,  
            set_attribute_value__attribute_name,
            set_attribute_value__value
        );

        insert into wf_attribute_value_audit
            (case_id, attribute_id, journal_id, attr_value)
        values
            (v_case_id, v_attribute_id, set_attribute_value__journal_id, 
             set_attribute_value__value);

        return 0; 
end;' language 'plpgsql';


-- function get_attribute_value
create or replace function workflow_case__get_attribute_value (integer,varchar)
returns varchar as '
declare
  get_attribute_value__case_id                alias for $1;  
  get_attribute_value__attribute_name         alias for $2;  
begin
        return acs_object__get_attribute (
            get_attribute_value__case_id,
            get_attribute_value__attribute_name
        );
     
end;' language 'plpgsql';


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


-- procedure remove_task_assignment
create or replace function workflow_case__remove_task_assignment (integer,integer,boolean)
returns integer as '
declare
  remove_task_assignment__task_id                alias for $1;  
  remove_task_assignment__party_id               alias for $2;  
  remove_task_assignment__permanent_p		 alias for $3;
  v_num_assigned                                 integer;        
  v_case_id                                      integer; 
  v_role_key					 wf_roles.role_key%TYPE;       
  v_workflow_key                                 varchar;  
  v_transition_key                               varchar;  
  v_context_key                                  varchar;  
  callback_rec                                   record;
begin
        -- get some information

        select ta.case_id, ta.transition_key, tr.role_key, ta.workflow_key, c.context_key
          into v_case_id, v_transition_key, v_role_key, v_workflow_key, v_context_key
          from wf_tasks ta, wf_transitions tr, wf_cases c
         where ta.task_id = remove_task_assignment__task_id
           and tr.workflow_key = ta.workflow_key
           and tr.transition_key = ta.transition_key
           and c.case_id = ta.case_id;

        -- make the same assignment as a manual assignment

        if remove_task_assignment__permanent_p = ''t'' then
            perform workflow_case__remove_manual_assignment (
                v_case_id,
                v_role_key,
                remove_task_assignment__party_id
            );
        end if;

        -- now delete the row
 
        delete 
          from wf_task_assignments
         where task_id = remove_task_assignment__task_id
           and party_id = remove_task_assignment__party_id;

        -- check if the task now became unassigned

        select count(*) 
          into v_num_assigned
          from wf_task_assignments
         where task_id = remove_task_assignment__task_id;

        if v_num_assigned > 0 then
            return 0;
        end if;

        -- yup, the task is now unassigned; fire the callback

        select unassigned_callback, unassigned_custom_arg
          into callback_rec
            from   wf_context_transition_info
            where  workflow_key = v_workflow_key
            and    context_key = v_context_key
            and    transition_key = v_transition_key;
        if FOUND then
            PERFORM workflow_case__execute_unassigned_callback (
                callback_rec.unassigned_callback,
                remove_task_assignment__task_id,
                callback_rec.unassigned_custom_arg
            );
        end if;

        return 0; 
end;' language 'plpgsql';


-- procedure clear_task_assignments
create or replace function workflow_case__clear_task_assignments (integer,boolean)
returns integer as '
declare
  clear_task_assignments__task_id                alias for $1;  
  clear_task_assignments__permanent_p		 alias for $2;
  v_case_id                                      integer;        
  v_transition_key                               varchar;  
  v_role_key					 wf_roles.role_key%TYPE;
  v_workflow_key                                 varchar;  
  v_context_key                                  varchar;  
  v_callback                                     varchar;  
  v_custom_arg                                   varchar; 
begin
        -- get some information

        select ta.case_id, ta.transition_key, tr.role_key, ta.workflow_key, c.context_key
          into v_case_id, v_transition_key, v_role_key, v_workflow_key, v_context_key
          from wf_tasks ta, wf_transitions tr, wf_cases c
         where ta.task_id = clear_task_assignments__task_id
           and tr.workflow_key = ta.workflow_key
           and tr.transition_key = ta.transition_key
           and c.case_id = ta.case_id;

        -- make the unassignment stick as a manual assignment

        if clear_task_assignments__permanent_p = ''t'' then
            perform workflow_case__clear_manual_assignments (
                v_case_id,
                v_role_key
            );
        end if;

        -- delete the rows


        delete 
        from   wf_task_assignments
        where  task_id = clear_task_assignments__task_id;

        -- fire the unassigned callback

        select unassigned_callback, unassigned_custom_arg
        into   v_callback, v_custom_arg
        from   wf_context_transition_info
        where  workflow_key = v_workflow_key
        and    context_key  = v_context_key
        and    transition_key = v_transition_key;

        PERFORM workflow_case__execute_unassigned_callback (
            v_callback,
            clear_task_assignments__task_id,
            v_custom_arg
        );

        return 0; 
end;' language 'plpgsql';


-- procedure set_case_deadline 
create or replace function workflow_case__set_case_deadline (integer,varchar,timestamptz)
returns integer as '
declare
  set_case_deadline__case_id		alias for $1;
  set_case_deadline__transition_key	alias for $2;
  set_case_deadline__deadline		alias for $3;
  v_workflow_key			wf_workflows.workflow_key%TYPE;
begin
        -- delete the current deadline row
        delete
          from wf_case_deadlines
         where case_id = set_case_deadline__case_id
           and transition_key = set_case_deadline__transition_key;

        if set_case_deadline__deadline is not null then
            -- get some info
            select workflow_key
              into v_workflow_key
              from wf_cases
             where case_id = set_case_deadline__case_id;

            -- insert new deadline row
            insert into wf_case_deadlines (
                case_id,
                workflow_key,
                transition_key,
                deadline
            ) values (
                set_case_deadline__case_id,
                v_workflow_key,
                set_case_deadline__transition_key,
                set_case_deadline__deadline
            );
        end if;
  return 0;
end;' language 'plpgsql';


-- procedure remove_case_deadline
create or replace function workflow_case__remove_case_deadline (integer,varchar)
returns integer as '
declare
  remove_case_deadline__case_id		alias for $1;
  remove_case_deadline__transition_key	alias for $2;
begin
      perform workflow_case__set_case_deadline (
            remove_case_deadline__case_id,
            remove_case_deadline__transition_key,
            null
        );

  return 0;
end;' language 'plpgsql';









-- function evaluate_guard
create or replace function workflow_case__evaluate_guard (varchar,varchar,integer,varchar,varchar,varchar,varchar)
returns boolean as '
declare
  evaluate_guard__callback               alias for $1;  
  evaluate_guard__custom_arg             alias for $2;  
  evaluate_guard__case_id                alias for $3;  
  evaluate_guard__workflow_key           alias for $4;  
  evaluate_guard__transition_key         alias for $5;  
  evaluate_guard__place_key              alias for $6;  
  evaluate_guard__direction              alias for $7;  
  v_guard_happy_p                        boolean;
  v_rec                                  record;
  v_str                                  text default '''';
begin
        if evaluate_guard__callback = '''' or 
           evaluate_guard__callback is null then
            -- null guard evaluates to true
            return ''t'';
        else
            if evaluate_guard__callback = ''#'' then
                return ''f'';
            else
                v_str := ''select '' || evaluate_guard__callback
                || ''('' || 
                evaluate_guard__case_id || '','' || 
                quote_literal(evaluate_guard__workflow_key) || '','' || 
                quote_literal(evaluate_guard__transition_key) || '','' || 
                quote_literal(evaluate_guard__place_key) || '','' || 
                quote_literal(evaluate_guard__direction) || '','' || 
                coalesce(quote_literal(evaluate_guard__custom_arg),''null'') || '') as guard_happy_p'';
                raise notice ''str = %'', v_str;
                for v_rec in 
                    execute v_str
                LOOP
                    return v_rec.guard_happy_p;                        
                end LOOP;
            end if;
        end if;

        return null;
     
end;' language 'plpgsql';


-- procedure execute_transition_callback
create or replace function workflow_case__execute_transition_callback (varchar,varchar,integer,varchar)
returns integer as '
declare
  execute_transition_callback__callback               alias for $1;  
  execute_transition_callback__custom_arg             alias for $2;  
  execute_transition_callback__case_id                alias for $3;  
  execute_transition_callback__transition_key         alias for $4;  
  v_str                                               text;
begin
        if execute_transition_callback__callback != '''' and execute_transition_callback__callback is not null then 
            v_str := ''select '' || execute_transition_callback__callback
            || ''('' || execute_transition_callback__case_id || '','' || 
            quote_literal(execute_transition_callback__transition_key) || '','' || 
            coalesce(quote_literal(execute_transition_callback__custom_arg),''null'') || '')'';
            execute v_str;
        end if;

        return 0; 
end;' language 'plpgsql';


-- function execute_time_callback
create or replace function workflow_case__execute_time_callback (varchar,varchar,integer,varchar)
returns timestamptz as '
declare
  execute_time_callback__callback               alias for $1;  
  execute_time_callback__custom_arg             alias for $2;  
  execute_time_callback__case_id                alias for $3;  
  execute_time_callback__transition_key         alias for $4;  
  v_rec                                         record;
  v_str                                         text;
begin
        if execute_time_callback__callback = '''' or execute_time_callback__callback is null then
            raise EXCEPTION ''-20000: There''''s no time_callback function for the timed transition "%"'', execute_time_callback__transition_key;
        end if;
 
        v_str := ''select '' || execute_time_callback__callback || ''('' || 
                 execute_time_callback__case_id || '','' || 
                 quote_literal(execute_time_callback__transition_key) || '','' || 
                 coalesce(quote_literal(execute_time_callback__custom_arg),''null'') || '') as trigger_time'';

        for v_rec in execute v_str
        LOOP
            return v_rec.trigger_time;
        end LOOP;

        return null;
     
end;' language 'plpgsql';


-- function get_task_deadline
create or replace function workflow_case__get_task_deadline (varchar,varchar,varchar,integer,varchar)
returns timestamptz as '
declare
  get_task_deadline__callback               alias for $1;  
  get_task_deadline__custom_arg             alias for $2;  
  get_task_deadline__attribute_name         alias for $3;  
  get_task_deadline__case_id                alias for $4;  
  get_task_deadline__transition_key         alias for $5;  
  v_deadline                                timestamptz;
  v_rec                                     record;
  v_str                                     varchar;
begin
        /*
         * 1. or if there is a row in wf_case_deadlines, we use that
         * 2. if there is a callback, we execute that
         * 3. otherwise, if there is an attribute, we use that
         */

        /* wf_case_deadlines */
        select deadline into v_deadline
            from wf_case_deadlines
            where case_id = get_task_deadline__case_id
            and   transition_key = get_task_deadline__transition_key;

        if NOT FOUND then
            if get_task_deadline__callback != '''' and get_task_deadline__callback is not null then
                /* callback */
                v_str := ''select '' || get_task_deadline__callback || ''('' || 
                         get_task_deadline__case_id || '','' || 
                         quote_literal(get_task_deadline__transition_key) || '','' || 
                         coalesce(quote_literal(get_task_deadline__custom_arg),''null'') || '') as deadline'';

                for v_rec in execute v_str
                LOOP
                    v_deadline := v_rec.deadline;
                    exit;
                end LOOP;
            else if get_task_deadline__attribute_name != '''' and get_task_deadline__attribute_name is not null then
                /* attribute */
                v_deadline := acs_object__get_attribute (
                    get_task_deadline__case_id,
                    get_task_deadline__attribute_name
                );
            else 
                v_deadline := null;
            end if; end if;
        end if;
        
        return v_deadline;
     
end;' language 'plpgsql';


-- function execute_hold_timeout_callback
create or replace function workflow_case__execute_hold_timeout_callback (varchar,varchar,integer,varchar)
returns timestamptz as '
declare
  execute_hold_timeout_callback__callback               alias for $1;  
  execute_hold_timeout_callback__custom_arg             alias for $2;  
  execute_hold_timeout_callback__case_id                alias for $3;  
  execute_hold_timeout_callback__transition_key         alias for $4;  
  v_hold_timeout                                        timestamptz;
  v_rec                                                 record;
  v_str                                                 text;
begin
        if execute_hold_timeout_callback__callback = '''' or execute_hold_timeout_callback__callback is null then
            return null;
        end if;
 
        v_str := ''select '' || execute_hold_timeout_callback__callback 
              || ''('' ||
              execute_hold_timeout_callback__case_id || '','' ||
              quote_literal(execute_hold_timeout_callback__transition_key) || 
              '','' ||
              coalesce(quote_literal(execute_hold_timeout_callback__custom_arg),''null'') || '') as hold_timeout'';

        for v_rec in execute v_str
        LOOP
           return v_rec.hold_timeout;
        end LOOP;

        return null;
     
end;' language 'plpgsql';


-- procedure execute_unassigned_callback
create or replace function workflow_case__execute_unassigned_callback (varchar,integer,varchar)
returns integer as '
declare
  callback               alias for $1;  
  task_id                alias for $2;  
  custom_arg             alias for $3; 
  v_str                  text; 
begin
        if callback != '''' and callback is not null then
            v_str := ''select '' || callback
                     || ''('' || task_id || '','' || 
                     coalesce(quote_literal(custom_arg),''null'') 
                     || '')'';

            execute v_str;
        end if;

        return 0; 
end;' language 'plpgsql';


-- procedure set_task_assignments
create or replace function workflow_case__set_task_assignments (integer,varchar,varchar)
returns integer as '
declare
  set_task_assignments__task_id                alias for $1;  
  set_task_assignments__callback               alias for $2;  
  set_task_assignments__custom_arg             alias for $3;  
  v_done_p                                     boolean;
  case_assignment_rec                          record;
  context_assignment_rec                       record;
  v_str                                        text;
begin

        /* Find out who to assign the given task to.
         *
         * 1. See if there are rows in wf_case_assignments.
         * 2. If not, and a callback is defined, execute that.
         * 3. Otherwise, grab the assignment from the workflow context.
         *
         * (We used to use the callback first, but that makes
         *  reassignment of tasks difficult.)
         */

        v_done_p := ''f'';
        for case_assignment_rec in  select party_id
              from wf_case_assignments ca, wf_tasks t, wf_transitions tr
             where t.task_id = set_task_assignments__task_id
               and ca.case_id = t.case_id
               and ca.role_key = tr.role_key
               and tr.workflow_key = t.workflow_key
               and tr.transition_key = t.transition_key
        LOOP
            v_done_p := ''t'';
            PERFORM workflow_case__add_task_assignment (
                set_task_assignments__task_id,
                case_assignment_rec.party_id,
		''f''
            );
        end loop;
        if v_done_p != ''t'' then

            if set_task_assignments__callback != '''' and set_task_assignments__callback is not null then
                v_str := ''select ''|| set_task_assignments__callback || ''('' || 
                set_task_assignments__task_id || '','' || 
                coalesce(quote_literal(set_task_assignments__custom_arg),''null'') || '')'';
                execute v_str;
            else
                for context_assignment_rec in  
                    select party_id
		    from wf_context_assignments ca, wf_cases c, wf_tasks t, wf_transitions tr
		    where t.task_id = set_task_assignments__task_id
		    and c.case_id = t.case_id
		    and ca.context_key = c.context_key
		    and ca.workflow_key = t.workflow_key
		    and ca.role_key = tr.role_key
		    and tr.workflow_key = t.workflow_key
		    and tr.transition_key = t.transition_key
                LOOP
                    PERFORM workflow_case__add_task_assignment (
                        set_task_assignments__task_id,
                        context_assignment_rec.party_id,
			''f''
                    );
                end LOOP;
            end if;
        end if;

        return 0; 
end;' language 'plpgsql';


-- procedure add_token
create or replace function workflow_case__add_token (integer,varchar,integer)
returns integer as '
declare
  add_token__case_id                alias for $1;  
  add_token__place_key              alias for $2;  
  add_token__journal_id             alias for $3;  
  v_token_id                        integer;
  v_workflow_key                    varchar;
begin
        select wf_token_id_seq.nextval into v_token_id from dual;
        
        select workflow_key into v_workflow_key 
        from   wf_cases c 
        where  c.case_id = add_token__case_id;
    
        insert into wf_tokens 
            (token_id, case_id, workflow_key, place_key, state, produced_journal_id)
        values 
            (v_token_id, add_token__case_id, v_workflow_key, add_token__place_key, 
            ''free'', add_token__journal_id);

        return 0; 
end;' language 'plpgsql';


-- procedure lock_token
create or replace function workflow_case__lock_token (integer,varchar,integer,integer)
returns integer as '
declare
  lock_token__case_id                alias for $1;  
  lock_token__place_key              alias for $2;  
  lock_token__journal_id             alias for $3;  
  lock_token__task_id                alias for $4;  
begin
        -- FIXME: rownum 
--        update wf_tokens
--        set    state = ''locked'',
--               locked_task_id = lock_token__task_id,
--               locked_date = now(),
--               locked_journal_id = lock_token__journal_id
--        where  case_id = lock_token__case_id
--        and    place_key = lock_token__place_key
--        and    state = ''free''
--        and    rownum = 1;

        update wf_tokens
        set    state = ''locked'',
               locked_task_id = lock_token__task_id,
               locked_date = now(),
               locked_journal_id = lock_token__journal_id
        where  token_id = (select token_id 
                             from wf_tokens 
                            where case_id = lock_token__case_id
                              and place_key = lock_token__place_key
                              and state = ''free''
                            limit 1);

        return 0; 
end;' language 'plpgsql';


-- procedure release_token
create or replace function workflow_case__release_token (integer,integer)
returns integer as '
declare
  release_token__task_id                alias for $1;  
  release_token__journal_id             alias for $2;  
  token_rec                             record;
begin
        /* Add a new token for each released one */
        for token_rec in 
            select token_id, 
                   case_id, 
                   place_key
            from   wf_tokens
            where  state = ''locked''
            and    locked_task_id = release_token__task_id
        LOOP
            PERFORM workflow_case__add_token (
                token_rec.case_id,
                token_rec.place_key,
                release_token__journal_id
            );
        end loop;

        /* Mark the released ones canceled */
        update wf_tokens
        set    state = ''canceled'',
               canceled_date = now(),
               canceled_journal_id = release_token__journal_id
        where  state = ''locked''
        and    locked_task_id = release_token__task_id;

        return 0; 
end;' language 'plpgsql';


-- procedure consume_token
create or replace function workflow_case__consume_token (integer,varchar,integer,integer)
returns integer as '
declare
  consume_token__case_id                alias for $1;  
  consume_token__place_key              alias for $2;  
  consume_token__journal_id             alias for $3;  
  consume_token__task_id                alias for $4;  -- default null  
begin
        if consume_token__task_id is null then
            update wf_tokens
            set    state = ''consumed'',
                   consumed_date = now(),
                   consumed_journal_id = consume_token__journal_id
            where  token_id = (select token_id 
                                 from wf_tokens 
                                where case_id = consume_token__case_id
                                  and place_key = consume_token__place_key
                                  and state = ''free''
                                limit 1);
        else
            update wf_tokens
            set    state = ''consumed'',
                   consumed_date = now(),
                   consumed_journal_id = consume_token__journal_id
            where  case_id = consume_token__case_id
            and    place_key = consume_token__place_key
            and    state = ''locked''
            and    locked_task_id = consume_token__task_id;
        end if;

        return 0; 
end;' language 'plpgsql';


-- procedure sweep_automatic_transitions
create or replace function workflow_case__sweep_automatic_transitions (integer,integer)
returns integer as '
declare
  sweep_automatic_transitions__case_id                alias for $1;  
  sweep_automatic_transitions__journal_id             alias for $2;  
  v_done_p                                            boolean:=''f'';       
  v_finished_p                                        boolean;       
  task_rec                                            record;
begin

        PERFORM workflow_case__enable_transitions(sweep_automatic_transitions__case_id);
        while v_done_p != ''t'' loop
            v_done_p := ''t'';
            v_finished_p := workflow_case__finished_p (
                sweep_automatic_transitions__case_id,
                sweep_automatic_transitions__journal_id);

            if v_finished_p = ''f'' then
                for task_rec in 
                    select task_id
                    from   wf_tasks ta, wf_transitions tr
                    where  tr.workflow_key = ta.workflow_key
                    and    tr.transition_key = ta.transition_key
                    and    tr.trigger_type = ''automatic''
                    and    ta.state = ''enabled''
                    and    ta.case_id = sweep_automatic_transitions__case_id
                LOOP
                    PERFORM workflow_case__fire_transition_internal (
                        task_rec.task_id,
                        sweep_automatic_transitions__journal_id
                    );

                    v_done_p := ''f'';
                end loop;
                PERFORM workflow_case__enable_transitions(sweep_automatic_transitions__case_id);
            end if;

        end loop;

        return 0; 
end;' language 'plpgsql';


-- function finished_p
create or replace function workflow_case__finished_p (integer,integer)
returns boolean as '
declare
  finished_p__case_id                alias for $1;  
  finished_p__journal_id             alias for $2;  
  v_case_state                       varchar;
  v_token_id                         integer;
  v_num_rows                         integer;
  v_journal_id                       integer;
begin
        select state into v_case_state 
        from   wf_cases 
        where  case_id = finished_p__case_id;

        if v_case_state = ''finished'' then
            return ''t'';
        else
            /* Let us see if the case is actually finished, but just not marked so */
            select case when count(*) = 0 then 0 else 1 end into v_num_rows
            from   wf_tokens
            where  case_id = finished_p__case_id
            and    place_key = ''end'';
    
            if v_num_rows = 0 then 
                return ''f'';
            else
                /* There is a token in the end place.
                 * Count the total integer of tokens to make sure the wf is well-constructed.
                 */
    
                select case when count(*) = 0 then 0
                            when count(*) = 1 then 1 
                                              else 2 
                        end into v_num_rows
                from   wf_tokens
                where  case_id = finished_p__case_id
                and    state in (''free'', ''locked'');
    
                if v_num_rows > 1 then 
                    raise EXCEPTION ''-20000: The workflow net is misconstructed: Some parallel executions have not finished.'';
                end if;
    
                /* Consume that token */
                select token_id into v_token_id
                from   wf_tokens
                where  case_id = finished_p__case_id
                and    state in (''free'', ''locked'');

                PERFORM workflow_case__consume_token (
                    finished_p__case_id,
                    ''end'',
                    finished_p__journal_id,
                    null
                );

                update wf_cases 
                set    state = ''finished'' 
                where  case_id = finished_p__case_id;

                /* Add an extra entry to the journal */
                v_journal_id := journal_entry__new (
                    null,
                    finished_p__case_id,
                    ''case finish'',
                    ''Case finished'',
                    now(),
                    null,
                    null,
                    null
                );

                return ''t'';
            end if;
        end if;
     
end;' language 'plpgsql';

-- The next two functions are called periodically by a scheduled Tcl script.

create or replace function workflow_case__sweep_timed_transitions () returns integer as '
declare
        v_journal_id    integer;
        trans_rec       record;
begin
        for trans_rec in select t.task_id, t.case_id, tr.transition_name
            from   wf_tasks t, wf_transitions tr
            where  trigger_time <= now()
            and    state = ''enabled''
            and    tr.workflow_key = t.workflow_key
            and    tr.transition_key = t.transition_key 
        LOOP
 
            /* Insert an entry to the journal so people will know it fired */

            v_journal_id := journal_entry__new (
                null,
                trans_rec.case_id, 
                ''task '' || trans_rec.task_id || '' fire time'',
                trans_rec.transition_name || '' automatically finished'',
                now(),
                null,
                null,
                ''Timed transition fired.''
            );
        
            /* Fire the transition */

            PERFORM workflow_case__fire_transition_internal (
                trans_rec.task_id,
                v_journal_id
            );

            /* Update the workflow internal state */

            PERFORM workflow_case__sweep_automatic_transitions(
                trans_rec.case_id,
                v_journal_id
            );

        end loop;

        return 0;
end;' language 'plpgsql';


create or replace function workflow_case__sweep_hold_timeout () returns integer as '
declare
        v_journal_id    integer;
        task_rec        record;
begin
        for task_rec in select t.task_id, t.case_id, tr.transition_name
            from   wf_tasks t, wf_transitions tr
            where  hold_timeout <= now()
            and    state = ''started''
            and    tr.workflow_key = t.workflow_key
            and    tr.transition_key = t.transition_key
        LOOP
 
            /* Insert an entry to the journal so people will know it was canceled */

            v_journal_id := journal_entry__new (
                null,
                task_rec.case_id, 
                ''task '' || task_rec.task_id || '' cancel timeout'',
                task_rec.transition_name || '' timed out'', 
                now(),
                null,
                null,
                ''The user''''s hold on the task timed out and the task was automatically canceled''
            );


            /* Cancel the task */

            PERFORM workflow_case__cancel_task (
                task_rec.task_id,
                v_journal_id
            );

        end loop;

        return 0;
end;' language 'plpgsql';

-- procedure notify_assignee
create or replace function workflow_case__notify_assignee (integer,integer,varchar,varchar)
returns integer as '
declare
  notify_assignee__task_id                alias for $1;  
  notify_assignee__user_id                alias for $2;  
  notify_assignee__callback               alias for $3;  
  notify_assignee__custom_arg             alias for $4;  
  v_deadline_pretty                       varchar;  
  v_object_name                           text; 
  v_transition_key                        wf_transitions.transition_key%TYPE;
  v_transition_name                       wf_transitions.transition_name%TYPE;
  v_party_from                            parties.party_id%TYPE;
  v_party_to                              parties.party_id%TYPE;
  v_subject                               text; 
  v_body                                  text; 
  v_request_id                            integer; 
  v_workflow_url			  text;      
  v_str                                   text;
begin
        select to_char(ta.deadline,''Mon fmDDfm, YYYY HH24:MI:SS''),
               acs_object__name(c.object_id),
               tr.transition_key,
               tr.transition_name
        into   v_deadline_pretty,
               v_object_name, 
               v_transition_key,
               v_transition_name
          from wf_tasks ta, wf_transitions tr, wf_cases c
         where ta.task_id = notify_assignee__task_id
           and c.case_id = ta.case_id
           and tr.workflow_key = c.workflow_key
           and tr.transition_key = ta.transition_key;

        select apm__get_value(p.package_id,''SystemURL'') || site_node__url(s.node_id)
          into v_workflow_url
          from site_nodes s, 
               apm_packages a,
               (select package_id
                from apm_packages 
                where package_key = ''acs-kernel'') p
         where s.object_id = a.package_id 
           and a.package_key = ''acs-workflow'';

        /* Mail sent from */
          select wfi.principal_party
	    into v_party_from
            from wf_context_workflow_info wfi, wf_tasks ta, wf_cases c
           where ta.task_id = notify_assignee__task_id
             and c.case_id = ta.case_id
             and wfi.workflow_key = c.workflow_key
             and wfi.context_key = c.context_key;
        if NOT FOUND then
            v_party_from := -1;
        end if;

        /* Subject */
        v_subject := ''Assignment: '' || v_transition_name || '' '' || v_object_name;

        /* Body */
        v_body := ''You have been assigned to a task.
'' || ''
Case        : '' || v_object_name || ''
Task        : '' || v_transition_name || ''
'';

        if v_deadline_pretty != '''' and v_deadline_pretty is not null then
            v_body := v_body || ''Deadline    : '' || v_deadline_pretty || ''
'';
        end if;

	v_body := v_body ||''Task website: ''||v_workflow_url||''task?task_id=''||notify_assignee__task_id||''
'';

        /* 
         * We would like to add a URL to go visit, but how do we get that URL?
         *
         * The notifications should really be sent from the application 
         * server layer, not from the database 
         */
    
        -- FIXME: last three args are also out varibles.

        if notify_assignee__callback != '''' and notify_assignee__callback is not null then
            v_str :=  ''select '' || notify_assignee__callback || '' ('' || 
                      notify_assignee__task_id || '','' ||
                      coalesce(quote_literal(notify_assignee__custom_arg),''null'') || 
                      '','' ||
                      notify_assignee__user_id || '','' ||
                      v_party_from || '','' ||
                      quote_literal(v_subject) || '','' ||
                      quote_literal(v_body) || '')'';

            execute v_str;
        else
            v_request_id := acs_mail_nt__post_request (       
                v_party_from,                 -- party_from
                notify_assignee__user_id,     -- party_to
                ''f'',                        -- expand_group
                v_subject,                    -- subject
                v_body,                       -- message
                0                             -- max_retries
            );
        end if;

    return 0; 
end;' language 'plpgsql';


-- procedure enable_transitions
create or replace function workflow_case__enable_transitions (integer)
returns integer as '
declare
  enable_transitions__case_id                alias for $1;  
  v_task_id                                  integer;        
  v_workflow_key                             varchar;  
  v_trigger_time                             timestamptz;     
  v_deadline_date                            timestamptz;     
  v_party_from                               integer;       
  v_subject                                  varchar;  
  v_body                                     text; 
  v_num_assigned                             integer; 
  trans_rec                                  record;
begin
        select workflow_key into v_workflow_key 
        from   wf_cases 
        where  case_id = enable_transitions__case_id;
    
        /* we mark tasks overridden if they were once enabled, but are no longer so */

        update wf_tasks 
        set    state = ''overridden'',
               overridden_date = now()
        where  case_id = enable_transitions__case_id 
        and    state = ''enabled''
        and    transition_key not in 
            (select transition_key 
             from wf_enabled_transitions 
             where case_id = enable_transitions__case_id);
    

        /* insert a task for the transitions that are enabled but have no task row */

        for trans_rec in select et.transition_key,
                   et.transition_name, 
                   et.trigger_type, 
                   et.enable_callback,
                   et.enable_custom_arg, 
                   et.time_callback, 
                   et.time_custom_arg,
                   et.deadline_callback,
                   et.deadline_custom_arg,
                   et.deadline_attribute_name,
                   et.notification_callback,
                   et.notification_custom_arg,
                   et.unassigned_callback,
                   et.unassigned_custom_arg,
                   et.estimated_minutes,
                   cr.assignment_callback,
                   cr.assignment_custom_arg
              from wf_enabled_transitions et left outer join wf_context_role_info cr
		    on (et.workflow_key = cr.workflow_key and et.role_key = cr.role_key)
             where et.case_id = enable_transitions__case_id
               and not exists (select 1 from wf_tasks 
                               where case_id = enable_transitions__case_id
                               and   transition_key = et.transition_key
                               and   state in (''enabled'', ''started'')) 
        LOOP

            v_trigger_time := null;
            v_deadline_date := null;

            if trans_rec.trigger_type = ''user'' then
                v_deadline_date := workflow_case__get_task_deadline (
                    trans_rec.deadline_callback, 
                    trans_rec.deadline_custom_arg,
                    trans_rec.deadline_attribute_name,
                    enable_transitions__case_id, 
                    trans_rec.transition_key
                );
            else if trans_rec.trigger_type = ''time'' then
		    v_trigger_time := workflow_case__execute_time_callback (
                                        trans_rec.time_callback, 
                                        trans_rec.time_custom_arg,
                                        enable_transitions__case_id, 
                                        trans_rec.transition_key);
		 end if;
            end if;

            /* we are ready to insert the row */
            select wf_task_id_seq.nextval into v_task_id from dual;

            insert into wf_tasks (
                task_id, case_id, workflow_key, transition_key, 
                deadline, trigger_time, estimated_minutes
            ) values (
                v_task_id, enable_transitions__case_id, v_workflow_key, 
                trans_rec.transition_key,
                v_deadline_date, v_trigger_time, trans_rec.estimated_minutes
            );
            
            PERFORM workflow_case__set_task_assignments (
                v_task_id,
                trans_rec.assignment_callback,
                trans_rec.assignment_custom_arg
            );

            /* Execute the transition enabled callback */
            PERFORM workflow_case__execute_transition_callback (
                trans_rec.enable_callback, 
                trans_rec.enable_custom_arg,
                enable_transitions__case_id, 
                trans_rec.transition_key
            );

            select count(*) into v_num_assigned
            from   wf_task_assignments
            where  task_id = v_task_id;

            if v_num_assigned = 0 then
                PERFORM workflow_case__execute_unassigned_callback (
                    trans_rec.unassigned_callback,
                    v_task_id,
                    trans_rec.unassigned_custom_arg
                );
            end if;

        end loop;

        return 0; 
end;' language 'plpgsql';


-- procedure fire_transition_internal
create or replace function workflow_case__fire_transition_internal (integer,integer)
returns integer as '
declare
  fire_transition_internal__task_id                alias for $1;  
  fire_transition_internal__journal_id             alias for $2;  
  v_case_id                                        integer;        
  v_state                                          varchar;   
  v_transition_key                                 varchar;  
  v_workflow_key                                   varchar;  
  v_place_key                                      varchar;  
  v_direction                                      varchar;    
  v_guard_happy_p                                  boolean;       
  v_fire_callback                                  varchar;  
  v_fire_custom_arg                                text; 
  v_found_happy_guard                              boolean;       
  v_locked_task_id                                 integer;   
  place_rec                                        record;     
begin
        select t.case_id, t.state, t.workflow_key, t.transition_key, ti.fire_callback, ti.fire_custom_arg
        into   v_case_id, v_state, v_workflow_key, v_transition_key, v_fire_callback, v_fire_custom_arg
        from   wf_tasks t, wf_cases c, wf_transition_info ti
        where  t.task_id = fire_transition_internal__task_id
        and    c.case_id = t.case_id
        and    ti.context_key = c.context_key
        and    ti.workflow_key = c.workflow_key
        and    ti.transition_key = t.transition_key;

        /* Check that the state is either started or enabled */

        if v_state = ''enabled'' then 
            v_locked_task_id := null;
        else if v_state = ''started'' then
            v_locked_task_id := fire_transition_internal__task_id;
        else 
            raise EXCEPTION ''-20000: Can''''t fire the transition if it''''s not in state enabled or started'';
        end if; end if;

        /* Mark the task finished */

        update wf_tasks
        set    state = ''finished'',
               finished_date = now()
        where  task_id = fire_transition_internal__task_id;


        /* Consume the tokens */

        for place_rec in select *
        from   wf_transition_places tp
        where  tp.workflow_key = v_workflow_key
        and    tp.transition_key = v_transition_key
        LOOP 
            PERFORM workflow_case__consume_token (
                v_case_id,
                place_rec.place_key,
                fire_transition_internal__journal_id,
                v_locked_task_id
             );
        end loop;

    
        /* Spit out new tokens in the output places */

        v_found_happy_guard := ''f'';
        for place_rec in 
        select *
        from   wf_transition_places tp
        where  tp.workflow_key = v_workflow_key
        and    tp.transition_key = v_transition_key
        and    direction = ''out''
        LOOP
            v_place_key := place_rec.place_key;
            v_direction := place_rec.direction;

            v_guard_happy_p := workflow_case__evaluate_guard(
                place_rec.guard_callback, 
                place_rec.guard_custom_arg,
                v_case_id, 
                v_workflow_key, 
                v_transition_key, 
                v_place_key, 
                v_direction
            );
    
            if v_guard_happy_p = ''t'' then
                v_found_happy_guard := ''t'';
                PERFORM workflow_case__add_token (
                    v_case_id, 
                    place_rec.place_key,
                    fire_transition_internal__journal_id
                );
            end if;
        end loop;


        /* If we did not find any happy guards, look for arcs with the special hash (#) guard */

        if v_found_happy_guard = ''f'' then
            for place_rec in 
                select place_key
                from   wf_transition_places tp
                where  tp.workflow_key = v_workflow_key
                and    tp.transition_key = v_transition_key
                and    tp.direction = ''out''
                and    tp.guard_callback = ''#''
            loop

                PERFORM workflow_case__add_token (
                    v_case_id, 
                    place_rec.place_key,
                    fire_transition_internal__journal_id
                );
            end loop;
        end if;


        /* Execute the transition fire callback */

        PERFORM workflow_case__execute_transition_callback (
            v_fire_callback, 
            v_fire_custom_arg, 
            v_case_id, 
            v_transition_key
        );

        return 0; 
end;' language 'plpgsql';


-- procedure ensure_task_in_state
create or replace function workflow_case__ensure_task_in_state (integer,varchar)
returns integer as '
declare
  ensure_task_in_state__task_id         alias for $1;  
  ensure_task_in_state__state           alias for $2;  
  v_count                               integer;        
begin
        select case when count(*) = 0 then 0 else 1 end into v_count
        from   wf_tasks 
        where  task_id = ensure_task_in_state__task_id
        and    state = ensure_task_in_state__state;
    
        if v_count != 1 then
            raise EXCEPTION ''-20000: The task %  is not in state "%"'', ensure_task_in_state__task_id, ensure_task_in_state__state;
        end if;
        
        return 0; 
end;' language 'plpgsql';


-- procedure start_task
create or replace function workflow_case__start_task (integer,integer,integer)
returns integer as '
declare
  start_task__task_id                alias for $1;  
  start_task__user_id                alias for $2;  
  start_task__journal_id             alias for $3;  
  v_case_id                          integer;        
  v_workflow_key                     wf_workflows.workflow_key%TYPE;
  v_transition_key                   varchar(100);  
  v_hold_timeout_callback            varchar(100);  
  v_hold_timeout_custom_arg          varchar(4000); 
  v_hold_timeout                     timestamptz;     
  place_rec                          record;
begin
        PERFORM workflow_case__ensure_task_in_state(start_task__task_id, 
                                                    ''enabled'');
    
        select t.case_id, t.workflow_key, t.transition_key, ti.hold_timeout_callback, ti.hold_timeout_custom_arg 
        into   v_case_id, v_workflow_key, v_transition_key, v_hold_timeout_callback, v_hold_timeout_custom_arg
        from   wf_tasks t, wf_cases c, wf_transition_info ti
        where  t.task_id = start_task__task_id
        and    c.case_id = t.case_id
        and    ti.context_key = c.context_key
        and    ti.workflow_key = t.workflow_key
        and    ti.transition_key = t.transition_key;

        v_hold_timeout := workflow_case__execute_hold_timeout_callback (
                       v_hold_timeout_callback, 
                       v_hold_timeout_custom_arg, 
                       v_case_id, v_transition_key);

        /* Mark it started */

        update wf_tasks 
        set    state = ''started'', 
               started_date = now(),
               holding_user = start_task__user_id, 
               hold_timeout = v_hold_timeout
        where task_id = start_task__task_id;
    
        
        /* Reserve one token from each input place */

        for place_rec in select *
        from   wf_transition_places tp
        where  tp.workflow_key = v_workflow_key
        and    tp.transition_key = v_transition_key
        and    direction = ''in''
        LOOP
            PERFORM workflow_case__lock_token (  
                v_case_id,
                place_rec.place_key,
                start_task__journal_id,
                start_task__task_id
            );
        end loop;

        return 0; 
end;' language 'plpgsql';


-- procedure cancel_task
create or replace function workflow_case__cancel_task (integer,integer)
returns integer as '
declare
  cancel_task__task_id                alias for $1;  
  cancel_task__journal_id             alias for $2;  
  v_case_id                           integer;
begin
        PERFORM workflow_case__ensure_task_in_state (cancel_task__task_id, 
                                                    ''started'');
        select case_id into v_case_id 
        from wf_tasks 
        where task_id = cancel_task__task_id;
    
        /* Mark the task canceled */

        update wf_tasks 
        set    state = ''canceled'',
               canceled_date =  now()
        where  task_id = cancel_task__task_id;

    
        /* Release our reserved tokens */

        PERFORM workflow_case__release_token (
            cancel_task__task_id,
            cancel_task__journal_id
        );

        /* The workflow state has now changed, so we must run this */
        
        PERFORM workflow_case__sweep_automatic_transitions (
            v_case_id,
            cancel_task__journal_id
        );

        return 0; 
end;' language 'plpgsql';


-- procedure finish_task
create or replace function workflow_case__finish_task (integer,integer)
returns integer as '
declare
  finish_task__task_id                alias for $1;  
  finish_task__journal_id             alias for $2;  
  v_case_id                           integer;
begin
        select case_id into v_case_id
        from   wf_tasks
        where  task_id = finish_task__task_id;

        PERFORM workflow_case__fire_transition_internal (
            finish_task__task_id,
            finish_task__journal_id
        );

        PERFORM workflow_case__sweep_automatic_transitions (
            v_case_id,
            finish_task__journal_id
        );

        return 0; 
end;' language 'plpgsql';

create or replace function workflow_case__get_task_id (integer, integer)
returns integer as '
declare
  get_task_id__case_id         alias for $1;
  get_task_id__transition_key  alias for $2;
  v_task_id                    integer;
begin

  select task_id into v_task_id
  from wf_tasks
  where case_id = get_task_id__case_id and
    transition_key = get_task_id__transition_key;

  if not found then
    raise error ''Case % has no transition with key %'', get_task_id__case_id, get_task_id__transition_key;

  return v_task_id;end;' language 'plpgsql';


