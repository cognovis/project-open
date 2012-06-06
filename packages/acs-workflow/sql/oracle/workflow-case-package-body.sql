--
-- acs-workflow/sql/workflow-case-package-body.sql
--
-- Creates the PL/SQL package that provides the API for interacting
-- with a workflow case.
--
-- @author Lars Pind (lars@pinds.com)
--
-- @creation-date 2000-05-18
--
-- @cvs-id $Id$
--

create or replace package body workflow_case
is

    /*
     * FORWARD DECLARATIONS
     */

    procedure add_token (
        case_id         in number,
        place_key       in varchar2,
        journal_id      in number
    );

    procedure lock_token (
        case_id         in number,
        place_key       in varchar2,
        journal_id      in number,
        task_id         in number
    );

    procedure release_token (
        task_id         in number,
        journal_id      in number
    );

    procedure consume_token (
        case_id         in number,
        place_key       in varchar2,
        journal_id      in number,
        task_id         in number default null
    );

    procedure execute_unassigned_callback (
        callback        in varchar2,
        task_id         in number,
        custom_arg      in varchar2
    );

    procedure enable_transitions (
        case_id         in number
    );

    procedure sweep_automatic_transitions (
        case_id         in number,
        journal_id      in number
    );

    function finished_p(
        case_id         in number,
        journal_id      in number
    ) return char;

    procedure fire_transition_internal (
        task_id         in number,
        journal_id      in number
    );

    procedure start_task(
        task_id         in number,
        user_id         in number,
        journal_id      in number
    );

    procedure cancel_task(
        task_id         in number,
        journal_id      in number
    );

    procedure finish_task (
        task_id         in number,
        journal_id      in number
    );

    procedure notify_assignee(
        task_id         in wf_tasks.task_id%TYPE,
        user_id         in users.user_id%TYPE,
        callback        in wf_context_transition_info.notification_callback%TYPE,
        custom_arg      in wf_context_transition_info.notification_custom_arg%TYPE
    );

    /*
     * CURSORS
     */

    cursor input_places(
        workflow_key    in wf_workflows.workflow_key%TYPE,
        transition_key  in wf_transitions.transition_key%TYPE
    ) 
    return wf_transition_places%ROWTYPE 
    is
        select *
        from   wf_transition_places tp
        where  tp.workflow_key = input_places.workflow_key
        and    tp.transition_key = input_places.transition_key
        and    direction = 'in';
    

    cursor output_places (
        workflow_key    in wf_workflows.workflow_key%TYPE,
        transition_key  in wf_transitions.transition_key%TYPE
    ) 
    return wf_transition_places%ROWTYPE 
    is
        select *
        from   wf_transition_places tp
        where  tp.workflow_key = output_places.workflow_key
        and    tp.transition_key = output_places.transition_key
        and    direction = 'out';


    /* 
     * PUBLIC API
     */

    function new (
        case_id         in number default null,
        workflow_key    in varchar2,
        context_key     in varchar2 default null,
        object_id       in integer,
        creation_date   in date default sysdate,
        creation_user   in integer default null,
        creation_ip     in varchar2 default null
    ) 
    return integer
    is
        v_case_id               number;
        v_workflow_case_table   varchar2(30);
        v_context_key_for_query varchar2(100);
    begin
        if context_key is null then
            v_context_key_for_query := 'default';
        else
            v_context_key_for_query := context_key;
        end if;

        /* insert a row into acs_objects */
        v_case_id := acs_object.new(
            object_id => new.case_id,
            object_type => new.workflow_key,
            creation_date => new.creation_date,
            creation_user => new.creation_user,
            creation_ip => new.creation_ip
        );

        /* insert the case in to the general wf_cases table */
        insert into wf_cases 
            (case_id, workflow_key, context_key, object_id, state)
        values 
            (v_case_id, new.workflow_key, v_context_key_for_query, new.object_id, 'created');
            
        /* insert the case into the workflow-specific cases table */
        select table_name into v_workflow_case_table
        from   acs_object_types
        where  object_type = new.workflow_key;

        execute immediate 'insert into '||v_workflow_case_table||' (case_id) values (:1)'
        using v_case_id;

        return v_case_id;
    end new;


    procedure add_manual_assignment (
        case_id         in number,
        role_key        in varchar2,
        party_id        in number
    )
    is
        v_workflow_key varchar2(100);
        v_num_rows integer;
    begin
        select count(*)
          into v_num_rows
          from wf_case_assignments
         where case_id = add_manual_assignment.case_id
           and role_key = add_manual_assignment.role_key
           and party_id = add_manual_assignment.party_id;

        if v_num_rows = 0 then
	    select workflow_key 
	      into v_workflow_key 
	      from wf_cases 
	     where case_id = add_manual_assignment.case_id;
        
            insert into wf_case_assignments (
                case_id, 
                workflow_key, 
                role_key, 
                party_id
            ) values (
                add_manual_assignment.case_id, 
                v_workflow_key, 
                add_manual_assignment.role_key, 
                add_manual_assignment.party_id
            );
        end if;
    end add_manual_assignment;


    procedure remove_manual_assignment (
        case_id         in number,
        role_key        in varchar2,
        party_id        in number
    )
    is
        v_workflow_key varchar2(100);
    begin
        select workflow_key 
          into v_workflow_key 
          from wf_cases
         where case_id = remove_manual_assignment.case_id;
        
        delete 
          from wf_case_assignments
         where workflow_key = v_workflow_key
           and case_id = remove_manual_assignment.case_id
           and role_key = remove_manual_assignment.role_key
           and party_id = remove_manual_assignment.party_id;
    end remove_manual_assignment;

    procedure clear_manual_assignments (
        case_id         in number,
        role_key        in varchar2
    )
    is
        v_workflow_key varchar2(100);
    begin
        select workflow_key 
          into v_workflow_key
          from wf_cases 
         where case_id = clear_manual_assignments.case_id;
        
        delete 
          from wf_case_assignments 
         where workflow_key = v_workflow_key 
           and case_id = clear_manual_assignments.case_id
           and role_key = clear_manual_assignments.role_key;
    end clear_manual_assignments;


    procedure start_case (
        case_id         in number,
        creation_user   in integer default null,
        creation_ip     in varchar2 default null,
        msg             in varchar2 default null
    )
    is
        v_journal_id number;
    begin
        /* Add an entry to the journal */
        v_journal_id := journal_entry.new(
            object_id => start_case.case_id,
            action => 'case start',
            action_pretty => 'Case started',
            creation_user => start_case.creation_user,
            creation_ip => start_case.creation_ip,
            msg => start_case.msg
        );

        update wf_cases set state = 'active' where case_id = start_case.case_id;

        add_token(
            case_id => start_case.case_id, 
            place_key => 'start',
            journal_id => v_journal_id
        );

        /* Turn the wheels */
        sweep_automatic_transitions(
            case_id => start_case.case_id,
            journal_id => v_journal_id
        );
    end start_case;


    procedure del (
        case_id         in number
    )
    is
        v_workflow_case_table varchar2(30);
    begin
        /* delete attribute_value_audit, tokens, tasks  */
        delete from wf_attribute_value_audit where case_id = workflow_case.del.case_id;
        delete from wf_case_assignments where case_id = workflow_case.del.case_id;
        delete from wf_case_deadlines where case_id = workflow_case.del.case_id;
        delete from wf_tokens where case_id = workflow_case.del.case_id;
        delete from wf_task_assignments where task_id in (select task_id from wf_tasks where case_id = workflow_case.del.case_id);
        delete from wf_tasks where case_id = workflow_case.del.case_id;

        /* delete the journal */
        journal_entry.delete_for_object(workflow_case.del.case_id);
        
        /* delete from the workflow-specific cases table */
        select table_name into v_workflow_case_table
        from   acs_object_types ot, wf_cases c
        where  c.case_id = workflow_case.del.case_id
        and    object_type = c.workflow_key;
        
        execute immediate 'delete from '||v_workflow_case_table||' where case_id = :case_id'
        using in workflow_case.del.case_id;

        /* delete from the generic cases table */
        delete from wf_cases where case_id = workflow_case.del.case_id;

        /* delete from acs-objects */
        acs_object.del(workflow_case.del.case_id);
    end del;


    procedure suspend(
        case_id         in number,
        user_id         in number default null,
        ip_address      in varchar2 default null,
        msg             in varchar2 default null
    )
    is
        v_state varchar2(40);
        v_journal_id number;
    begin
        select state into v_state
        from   wf_cases
        where  case_id = suspend.case_id;

        if v_state != 'active' then
            raise_application_error(-20000, 'Only active cases can be suspended');
        end if;
        
        /* Add an entry to the journal */
        v_journal_id := journal_entry.new(
            object_id => suspend.case_id,
            action => 'case suspend',
            action_pretty => 'case suspended',
            creation_user => suspend.user_id,
            creation_ip => suspend.ip_address,
            msg => suspend.msg
        );

        update wf_cases
        set    state = 'suspended'
        where  case_id = suspend.case_id;
    end suspend;


    procedure resume(
        case_id         in number,
        user_id         in number default null,
        ip_address      in varchar2 default null,
        msg             in varchar2 default null
    )
    is
        v_state varchar2(40);
        v_journal_id number;
    begin
        select state into v_state
        from   wf_cases
        where  case_id = resume.case_id;

        if v_state != 'suspended' and v_state != 'canceled' then
            raise_application_error(-20000, 'Only suspended or canceled cases can be resumed');
        end if;

        /* Add an entry to the journal */
        v_journal_id := journal_entry.new(
            object_id => resume.case_id,
            action => 'case resume',
            action_pretty => 'case resumed',
            creation_user => resume.user_id,
            creation_ip => resume.ip_address,
            msg => resume.msg
        );

        update wf_cases
        set    state = 'active'
        where  case_id = resume.case_id;
    end resume;


    procedure cancel(
        case_id         in number,
        user_id         in number default null,
        ip_address      in varchar2 default null,
        msg             in varchar2 default null
    )
    is
        v_state varchar2(40);
        v_journal_id number;
    begin
        select state into v_state
        from   wf_cases
        where  case_id = cancel.case_id;

        if v_state != 'active' and v_state != 'suspended' then
            raise_application_error(-20000, 'Only active or suspended cases can be canceled');
        end if;

        /* Add an entry to the journal */
        v_journal_id := journal_entry.new(
            object_id => cancel.case_id,
            action => 'case cancel',
            action_pretty => 'Case canceled',
            creation_user => cancel.user_id,
            creation_ip => cancel.ip_address,
            msg => cancel.msg
        );

        update wf_cases
        set    state = 'canceled'
        where  case_id = cancel.case_id;
    end cancel;


    procedure fire_message_transition (
        task_id in number
    ) is
        v_case_id number;
        v_transition_name varchar2(100);
        v_trigger_type varchar2(40);
        v_journal_id number;
    begin
        select t.case_id, tr.transition_name, tr.trigger_type 
        into   v_case_id, v_transition_name, v_trigger_type
        from   wf_tasks t, wf_transitions tr
        where  t.task_id = fire_message_transition.task_id
        and    tr.workflow_key = t.workflow_key
        and    tr.transition_key = t.transition_key;

        if v_trigger_type != 'message' then
            raise_application_error(-20000, 'Transition '''||v_transition_name||''' is not message triggered');
        end if;

        /* Add an entry to the journal */
        v_journal_id := journal_entry.new(
            object_id => v_case_id,
            action => 'task '||fire_message_transition.task_id||' fire',
            action_pretty => v_transition_name || ' fired'
        );
        
        fire_transition_internal(
            task_id => fire_message_transition.task_id,
            journal_id => v_journal_id
        );

        sweep_automatic_transitions(
            case_id => v_case_id,
            journal_id => v_journal_id
        );
    end fire_message_transition;    


    /*
     * A wrapper for user tasks that uses the start/commit/cancel model for firing transitions.
     * Returns journal_id.
     */
    function begin_task_action (
        task_id         in number,
        action          in varchar2,
        action_ip       in varchar2,
        user_id         in number,
        msg             in varchar2 default null
    ) 
    return number 
    is
        v_state varchar2(40);
        v_journal_id number;
        v_case_id number;
        v_transition_name varchar2(100);
        v_num_rows number;
    begin
        select state into v_state
        from   wf_tasks
        where  task_id = begin_task_action.task_id;

        if begin_task_action.action = 'start' then
            if v_state != 'enabled' then
                raise_application_error(-20000, 'Task is in state '''||v_state||''', '||
                    'but it must be in state ''enabled'' to be started.');
            end if;
        
            select decode(count(*),0,0,1) into v_num_rows
            from   wf_user_tasks
            where  task_id = begin_task_action.task_id
            and    user_id = begin_task_action.user_id;
            
            if v_num_rows = 0 then
                raise_application_error(-20000, 'You are not assigned to this task.');
            end if;
        elsif begin_task_action.action = 'finish' or begin_task_action.action = 'cancel' then

            if v_state = 'started' then
                /* Is this user the holding user? */
                select decode(count(*),0,0,1) into v_num_rows
                from   wf_tasks
                where  task_id = begin_task_action.task_id
                and    holding_user = begin_task_action.user_id;
                if v_num_rows = 0 then  
                    raise_application_error(-20000, 'You are not the user currently working on this task.');
                end if;
            elsif v_state = 'enabled' then
                if begin_task_action.action = 'cancel' then
                    raise_application_error(-20000, 'You can only cancel a task in state ''started'', '||
                    'but this task is in state '''||v_state||'''');
                end if;

                /* Is this user assigned to this task? */
                select decode(count(*),0,0,1) into v_num_rows
                from   wf_user_tasks
                where  task_id = begin_task_action.task_id
                and    user_id = begin_task_action.user_id;
                if v_num_rows = 0 then  
                    raise_application_error(-20000, 'You are not assigned to this task.');
                end if;

                /* This task is finished without an explicit start.
                 * Store the user as the holding_user */
                update wf_tasks 
                set    holding_user = begin_task_action.user_id 
                where  task_id = begin_task_action.task_id;
            else
                raise_application_error(-20000, 'Task is in state '''||v_state||''', '||
                    'but it must be in state ''enabled'' or ''started'' to be finished');
            end if;

        elsif begin_task_action.action = 'comment' then
            -- We currently allow anyone to comment on a task
            -- (need this line because PL/SQL doens't like empty if blocks)
            v_num_rows := 0;
        end if;

        select  t.case_id, tr.transition_name into v_case_id, v_transition_name
        from    wf_tasks t, 
                wf_transitions tr
        where   t.task_id = begin_task_action.task_id
        and     tr.workflow_key = t.workflow_key
        and     tr.transition_key = t.transition_key;

        /* Insert a journal entry */

        v_journal_id := journal_entry.new(
            object_id => v_case_id,
            action => 'task '||begin_task_action.task_id||' '||begin_task_action.action,
            action_pretty => v_transition_name || ' ' || begin_task_action.action,
            creation_user => begin_task_action.user_id,
            creation_ip => begin_task_action.action_ip,
            msg => begin_task_action.msg
        );

        return v_journal_id;
    end begin_task_action;


    procedure end_task_action (
        journal_id      in number,
        action          in varchar2,
        task_id         in number
    ) 
    is
        v_user_id number;
    begin
        select creation_user into v_user_id
        from   acs_objects
        where  object_id = end_task_action.journal_id;

        /* Update the workflow state */

        if end_task_action.action = 'start' then
            start_task(end_task_action.task_id, v_user_id, end_task_action.journal_id);
        elsif end_task_action.action = 'finish' then
            finish_task(end_task_action.task_id, end_task_action.journal_id);
        elsif end_task_action.action = 'cancel' then
            cancel_task(end_task_action.task_id, end_task_action.journal_id);
        elsif end_task_action.action != 'comment' then
            raise_application_error(-20000, 'Unknown action ''' || end_task_action.action || '''');
        end if;

    end end_task_action;
    
    function task_action (
        task_id         in number,
        action          in varchar2,
        action_ip       in varchar2,
        user_id         in number,
        msg             in varchar2 default null
    ) return number
    is
        v_journal_id integer;
    begin
        v_journal_id := begin_task_action(
            task_id => task_action.task_id,
            action => task_action.action,
            action_ip => task_action.action_ip,
            user_id => task_action.user_id,
            msg => task_action.msg
        );
        
        end_task_action(
            journal_id => v_journal_id,
            action => task_action.action,
            task_id => task_action.task_id
        );

        return v_journal_id;        
    end task_action;


    procedure set_attribute_value (
        journal_id      in number,
        attribute_name  in varchar2,
        value           in varchar2
    ) 
    is 
        v_workflow_key varchar2(100);
        v_case_id number;
        v_attribute_id number;
    begin
        select o.object_type, o.object_id into v_workflow_key, v_case_id
        from   journal_entries je, acs_objects o
        where  je.journal_id = set_attribute_value.journal_id
        and    o.object_id = je.object_id;
        
        select attribute_id into v_attribute_id
        from acs_attributes
        where object_type = v_workflow_key
        and   attribute_name = set_attribute_value.attribute_name;
        
        acs_object.set_attribute(
            object_id_in => v_case_id,  
            attribute_name_in => set_attribute_value.attribute_name,
            value_in => set_attribute_value.value
        );

        insert into wf_attribute_value_audit
            (case_id, attribute_id, journal_id, attr_value)
        values
            (v_case_id, v_attribute_id, set_attribute_value.journal_id, set_attribute_value.value);
    end set_attribute_value;


    function get_attribute_value (
        case_id         in number,
        attribute_name  in varchar2
    ) 
    return varchar2
    is
    begin
        return acs_object.get_attribute(
            object_id_in => get_attribute_value.case_id,
            attribute_name_in => get_attribute_value.attribute_name
        );
    end get_attribute_value;
    

    procedure add_task_assignment (
        task_id         in number,
        party_id        in number,
        permanent_p     in char default 'f'
    )
    is
        v_count integer;
        v_workflow_key   wf_workflows.workflow_key%TYPE;
        v_context_key    wf_contexts.context_key%TYPE;
        v_case_id        wf_cases.case_id%TYPE;
        v_role_key       wf_roles.role_key%TYPE;
        v_transition_key wf_transitions.transition_key%TYPE;
        v_notification_callback   wf_context_transition_info.notification_callback%TYPE;
        v_notification_custom_arg wf_context_transition_info.notification_custom_arg%TYPE;

        -- might need to tune this query further
        cursor c_new_assigned_users is
            select distinct u.user_id
            from   users u
            where  u.user_id not in (
	            select distinct u2.user_id
	            from   wf_task_assignments tasgn2,
	                   party_approved_member_map m2,
	                   users u2
	            where  tasgn2.task_id = add_task_assignment.task_id
	            and    m2.party_id = tasgn2.party_id
	            and    u2.user_id = m2.member_id)
            and    exists (
                select 1 
                from   party_approved_member_map m
                where  m.member_id = u.user_id
                and    m.party_id = add_task_assignment.party_id
            );
        cursor c_callback is 
	    select notification_callback,
		   notification_custom_arg
	    from   wf_context_transition_info
	    where  context_key = v_context_key
	    and    workflow_key = v_workflow_key
	    and    transition_key = v_transition_key;
        callback_rec c_callback%ROWTYPE;

    begin
        -- get some needed information

        select ta.case_id, ta.workflow_key, ta.transition_key, tr.role_key, c.context_key
        into   v_case_id, v_workflow_key, v_transition_key, v_role_key, v_context_key
        from   wf_tasks ta, wf_transitions tr, wf_cases c
        where  ta.task_id = add_task_assignment.task_id
          and  tr.workflow_key = ta.workflow_key
          and  tr.transition_key = ta.transition_key
          and  c.case_id = ta.case_id;

        -- make the same assignment as a manual assignment

        if permanent_p = 't' then
	    /* We do this up-front, because 
	     * even though the user already had a task assignment, 
	     * he might not have a case assignment.
	     */
            add_manual_assignment(
                case_id => v_case_id,
                role_key => v_role_key,
                party_id => add_task_assignment.party_id
            );
        end if;

        -- check that we don't hit the unique constraint

        select count(*) into v_count
          from wf_task_assignments
         where task_id = add_task_assignment.task_id
           and party_id = add_task_assignment.party_id;

        if v_count > 0 then
            return;
        end if;

        -- get callback information

        open c_callback;
        fetch c_callback into callback_rec;

        if c_callback%FOUND then
            v_notification_callback := callback_rec.notification_callback;
            v_notification_custom_arg := callback_rec.notification_custom_arg;
        else
            v_notification_callback := null;
            v_notification_custom_arg := null;
        end if;

        -- notify any new assignees

        for v_assigned_user in c_new_assigned_users loop
            notify_assignee(
                task_id => add_task_assignment.task_id,
                user_id => v_assigned_user.user_id,
                callback => v_notification_callback,
                custom_arg => v_notification_custom_arg
            );
        end loop;

        -- do the insert

        insert into wf_task_assignments (
            task_id, 
            party_id
        ) values (
            add_task_assignment.task_id, 
            add_task_assignment.party_id
        );
    end add_task_assignment;

    procedure remove_task_assignment (
        task_id         in number,
        party_id        in number,
        permanent_p     in char default 'f'
    )
    is
        v_num_assigned number;
        v_case_id number;
        v_role_key wf_roles.role_key%TYPE;
        v_workflow_key varchar2(100);
        v_transition_key varchar2(100);
        v_context_key varchar2(100);

        cursor c_callback is
            select unassigned_callback, unassigned_custom_arg
              from wf_context_transition_info
             where workflow_key = v_workflow_key
               and context_key = v_context_key
               and transition_key = v_transition_key;
        callback_rec c_callback%ROWTYPE;
    begin
        -- get some information

        select ta.case_id, ta.transition_key, tr.role_key, ta.workflow_key, c.context_key
          into v_case_id, v_transition_key, v_role_key, v_workflow_key, v_context_key
          from wf_tasks ta, wf_transitions tr, wf_cases c
         where ta.task_id = remove_task_assignment.task_id
           and tr.workflow_key = ta.workflow_key
           and tr.transition_key = ta.transition_key
           and c.case_id = ta.case_id;

        -- make the same assignment as a manual assignment

        if permanent_p = 't' then
            remove_manual_assignment(
                case_id => v_case_id,
                role_key => v_role_key,
                party_id => remove_task_assignment.party_id
            );
        end if;

        -- now delete the row
 
        delete 
          from wf_task_assignments
         where task_id = remove_task_assignment.task_id
           and party_id = remove_task_assignment.party_id;

        -- check if the task now became unassigned

        select count(*) 
          into v_num_assigned
          from wf_task_assignments
         where task_id = remove_task_assignment.task_id;

        if v_num_assigned > 0 then
            return;
        end if;

        -- yup, the task is now unassigned; fire the callback

        open c_callback;
        fetch c_callback into callback_rec;

        if c_callback%FOUND then
            execute_unassigned_callback (
                callback => callback_rec.unassigned_callback,
                task_id => task_id,
                custom_arg => callback_rec.unassigned_custom_arg
            );
        end if;
        close c_callback;
    end remove_task_assignment;
  
    procedure clear_task_assignments (
        task_id         in number,
        permanent_p     in char default 'f'
    )
    is
        v_case_id number;
        v_transition_key varchar2(100);
        v_role_key wf_roles.role_key%TYPE;
        v_workflow_key varchar2(100);
        v_context_key varchar2(100);
        v_callback varchar2(100);
        v_custom_arg varchar2(4000);
    begin
        -- get some information

        select ta.case_id, ta.transition_key, tr.role_key, ta.workflow_key, c.context_key
          into v_case_id, v_transition_key, v_role_key, v_workflow_key, v_context_key
          from wf_tasks ta, wf_transitions tr, wf_cases c
         where ta.task_id = clear_task_assignments.task_id
           and tr.workflow_key = ta.workflow_key
           and tr.transition_key = ta.transition_key
           and c.case_id = ta.case_id;

        -- make the unassignment stick as a manual assignment

        if permanent_p = 't' then
            clear_manual_assignments(
                case_id => v_case_id,
                role_key => v_role_key
            );
        end if;

        -- delete the rows

        delete 
        from   wf_task_assignments
        where  task_id = clear_task_assignments.task_id;

        -- fire the unassigned callback

        select unassigned_callback, unassigned_custom_arg
        into   v_callback, v_custom_arg
        from   wf_context_transition_info
        where  workflow_key = v_workflow_key
        and    context_key  = v_context_key
        and    transition_key = v_transition_key;

        execute_unassigned_callback(
            callback => v_callback,
            task_id => task_id,
            custom_arg => v_custom_arg
        );
    end clear_task_assignments;

    procedure set_case_deadline (
        case_id         in wf_cases.case_id%TYPE,
        transition_key  in wf_transitions.transition_key%TYPE,
        deadline        date
    )
    is
        v_workflow_key wf_workflows.workflow_key%TYPE;
    begin
        -- delete the current deadline row
        delete
          from wf_case_deadlines
         where case_id = set_case_deadline.case_id
           and transition_key = set_case_deadline.transition_key;

        if deadline is not null then
            -- get some info
            select workflow_key
              into v_workflow_key
              from wf_cases
             where case_id = set_case_deadline.case_id;

            -- insert new deadline row
            insert into wf_case_deadlines (
                case_id,
                workflow_key,
                transition_key,
                deadline
            ) values (
                set_case_deadline.case_id,
                v_workflow_key,
                set_case_deadline.transition_key,
                set_case_deadline.deadline
            );
        end if;
    end set_case_deadline;

    procedure remove_case_deadline (
        case_id         in wf_cases.case_id%TYPE,
        transition_key  in wf_transitions.transition_key%TYPE
    )
    is
    begin
        set_case_deadline(
            case_id => remove_case_deadline.case_id,
            transition_key => remove_case_deadline.transition_key,
            deadline => null
        );
    end remove_case_deadline;










    /*
     * PRIVATE
     */

    function evaluate_guard (
        callback        in varchar2,
        custom_arg      in varchar2,
        case_id         in number, 
        workflow_key    in varchar2,
        transition_key  in varchar2, 
        place_key       in varchar2,
        direction       in varchar2
    ) 
    return char
    is
        v_guard_happy_p char(1);
    begin
        if callback is null then
            -- null guard evaluates to true
            return 't';
        else
            if callback = '#' then
                return 'f';
            else
                execute immediate 'begin :1 := ' || callback
                || '(:2, :3, :4, :5, :6, :7); end;'
                using out v_guard_happy_p, 
                      in case_id, 
                      in workflow_key, 
                      in transition_key, 
                      in place_key, 
                      in direction,
                      in custom_arg;
                return v_guard_happy_p;
            end if;
        end if;
    end evaluate_guard;


    procedure execute_transition_callback(
        callback        in varchar2,
        custom_arg      in varchar2,
        case_id         in number,
        transition_key  in varchar2
    ) 
    is
    begin
        if callback is not null then 
            execute immediate 'begin '||callback
            || '(:1, :2, :3); end;'
            using in case_id, 
                  in transition_key,
                  in custom_arg;
        end if;
    end execute_transition_callback;


    function execute_time_callback (
        callback        in varchar2,
        custom_arg      in varchar2,
        case_id         in number,
        transition_key  in varchar2
    ) 
    return date
    is
        v_trigger_time date;
    begin
        if callback is null then
            raise_application_error(-20000, 'There''s no time_callback function for the timed transition ''' || transition_key || '''');
        end if;
 
        execute immediate 'begin :1 := ' || callback 
        || '(:2, :3, :4); end;'
        using out v_trigger_time, 
              in case_id, 
              in transition_key,
              in custom_arg;
        
        return v_trigger_time;
    end execute_time_callback;


    function get_task_deadline (
        callback                in varchar2,
        custom_arg              in varchar2,
        attribute_name          in varchar2,
        case_id                 in number,
        transition_key          in varchar2
    ) 
    return date
    is
        cursor case_deadline_cur is
            select deadline
            from wf_case_deadlines
            where case_id = get_task_deadline.case_id
            and   transition_key = get_task_deadline.transition_key;
        v_deadline date;
    begin
        /*
         * 1. or if there's a row in wf_case_deadlines, we use that
         * 2. if there is a callback, we execute that
         * 3. otherwise, if there is an attribute, we use that
         */

        /* wf_case_deadlines */
        open case_deadline_cur;
        fetch case_deadline_cur into v_deadline;
        if case_deadline_cur%NOTFOUND then
            if callback is not null then
                /* callback */
                execute immediate 'begin :1 := ' || callback 
                || '(:2, :3, :4); end;'
                using out v_deadline, 
                      in case_id, 
                      in transition_key,
                      in custom_arg;
            elsif attribute_name is not null then
                /* attribute */
                v_deadline := acs_object.get_attribute(
                    object_id_in => get_task_deadline.case_id,
                    attribute_name_in => get_task_deadline.attribute_name
                );
            else 
                v_deadline := null;
            end if;
        end if;
        
        return v_deadline;
    end get_task_deadline;


    function execute_hold_timeout_callback (
        callback        in varchar2,
        custom_arg      in varchar2,
        case_id         in number,
        transition_key  in varchar2
    ) 
    return date
    is
        v_hold_timeout date;
    begin
        if callback is null then
            return null;
        end if;
 
        execute immediate 'begin :1 := ' || callback 
        || '(:2, :3, :4); end;'
        using out v_hold_timeout, 
              in case_id, 
              in transition_key,
              in custom_arg;
        
        return v_hold_timeout;
    end execute_hold_timeout_callback;


    procedure execute_unassigned_callback (
        callback        in varchar2,
        task_id         in number,
        custom_arg      in varchar2
    )
    is
    begin
        if callback is not null then
            execute immediate 'begin ' || callback
            || '(:1, :2); end;'
            using in task_id,
                  in custom_arg;
        end if;
    end execute_unassigned_callback;

    procedure set_task_assignments(
        task_id         in number,
        callback        in varchar2,
        custom_arg      in varchar2
    ) 
    is 
        cursor case_assignments is
            select party_id
              from wf_case_assignments ca, wf_tasks t, wf_transitions tr
             where t.task_id = set_task_assignments.task_id
               and ca.case_id = t.case_id
               and ca.role_key = tr.role_key
               and tr.workflow_key = t.workflow_key
               and tr.transition_key = t.transition_key;
        cursor context_assignments is
            select party_id
              from wf_context_assignments ca, wf_cases c, wf_tasks t, wf_transitions tr
             where t.task_id = set_task_assignments.task_id
               and c.case_id = t.case_id
               and ca.context_key = c.context_key
               and ca.workflow_key = t.workflow_key
               and ca.role_key = tr.role_key
               and tr.workflow_key = t.workflow_key
               and tr.transition_key = t.transition_key;
        v_done_p char(1);
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

        v_done_p := 'f';
        for case_assignment_rec in case_assignments loop
            v_done_p := 't';
            add_task_assignment (
                task_id => task_id,
                party_id => case_assignment_rec.party_id
            );
        end loop;

        if v_done_p != 't' then

            if callback is not null then
                execute immediate 'begin '|| set_task_assignments.callback 
                || '(:1, :2); end;'
                using in set_task_assignments.task_id,
                      in set_task_assignments.custom_arg;
            else
                for context_assignment_rec in context_assignments loop
                    add_task_assignment (
                        task_id => task_id,
                        party_id => context_assignment_rec.party_id
                    );
                end loop;
            end if;
        end if;
    end set_task_assignments;

 
    procedure add_token (
        case_id         in number,
        place_key       in varchar2,
        journal_id      in number
    ) 
    is 
        v_token_id number;
        v_workflow_key varchar2(100);
    begin
        select wf_token_id_seq.nextval into v_token_id from dual;
        
        select workflow_key into v_workflow_key 
        from   wf_cases c 
        where  c.case_id = add_token.case_id;
    
        insert into wf_tokens 
            (token_id, case_id, workflow_key, place_key, state, produced_journal_id)
        values 
            (v_token_id, add_token.case_id, v_workflow_key, add_token.place_key, 'free', add_token.journal_id);
    end add_token;
    

    procedure lock_token (
        case_id         in number,
        place_key       in varchar2,
        journal_id      in number,
        task_id         in number
    )
    is
    begin
        update wf_tokens
        set    state = 'locked',
               locked_task_id = lock_token.task_id,
               locked_date = sysdate,
               locked_journal_id = lock_token.journal_id
        where  case_id = lock_token.case_id
        and    place_key = lock_token.place_key
        and    state = 'free'
        and    rownum = 1;
    end lock_token;


    procedure release_token (
        task_id         in number,
        journal_id      in number
    )
    is
        cursor token_cur is
            select token_id, 
                   case_id, 
                   place_key
            from   wf_tokens
            where  state = 'locked'
            and    locked_task_id = release_token.task_id;
    begin
        /* Add a new token for each released one */
        for token_rec in token_cur loop
            add_token(
                case_id => token_rec.case_id,
                place_key => token_rec.place_key,
                journal_id => release_token.journal_id
            );
        end loop;

        /* Mark the released ones canceled */
        update wf_tokens
        set    state = 'canceled',
               canceled_date = sysdate,
               canceled_journal_id = release_token.journal_id
        where  state = 'locked'
        and    locked_task_id = release_token.task_id;
    end release_token;


    procedure consume_token (
        case_id         in number,
        place_key       in varchar2,
        journal_id      in number,
        task_id         in number default null
    )
    is
    begin
        if task_id is null then
            update wf_tokens
            set    state = 'consumed',
                   consumed_date = sysdate,
                   consumed_journal_id = consume_token.journal_id
            where  case_id = consume_token.case_id
            and    place_key = consume_token.place_key
            and    state = 'free'
            and    rownum = 1;
        else
            update wf_tokens
            set    state = 'consumed',
                   consumed_date = sysdate,
                   consumed_journal_id = consume_token.journal_id
            where  case_id = consume_token.case_id
            and    place_key = consume_token.place_key
            and    state = 'locked'
            and    locked_task_id = consume_token.task_id;
        end if;
    end consume_token;


    procedure sweep_automatic_transitions (
        case_id         in number,
        journal_id      in number
    ) is
        cursor enabled_automatic_transitions is
            select task_id
            from   wf_tasks ta, wf_transitions tr
            where  tr.workflow_key = ta.workflow_key
            and    tr.transition_key = ta.transition_key
            and    tr.trigger_type = 'automatic'
            and    ta.state = 'enabled'
            and    ta.case_id = sweep_automatic_transitions.case_id;
        v_done_p char(1);
        v_finished_p char(1);
    begin

        enable_transitions(case_id => sweep_automatic_transitions.case_id);

        loop
            v_done_p := 't';
            v_finished_p := finished_p(
                case_id => sweep_automatic_transitions.case_id,
                journal_id => sweep_automatic_transitions.journal_id);

            if v_finished_p = 'f' then
                for task_rec in enabled_automatic_transitions loop
                    fire_transition_internal(
                        task_id => task_rec.task_id,
                        journal_id => sweep_automatic_transitions.journal_id
                    );
                    v_done_p := 'f';
                end loop;
                enable_transitions(case_id => sweep_automatic_transitions.case_id);
            end if;

            exit when v_done_p = 't';
        end loop;
    end sweep_automatic_transitions;


    function finished_p (
        case_id         in number,
        journal_id      in number
    ) 
    return char
    is
        v_case_state varchar2(40);
        v_token_id number;
        v_num_rows number;
        v_journal_id number;
    begin
        select state into v_case_state 
        from   wf_cases 
        where  case_id = finished_p.case_id;

        if v_case_state = 'finished' then
            return 't';
        else
            /* Let's see if the case is actually finished, but just not marked so */
            select decode(count(*),0,0,1) into v_num_rows
            from   wf_tokens
            where  case_id = finished_p.case_id
            and    place_key = 'end';
    
            if v_num_rows = 0 then 
                return 'f';
            else
                /* There's a token in the end place.
                 * Count the total number of tokens to make sure the wf is well-constructed.
                 */
    
                select decode(count(*),0,0,1,1,2) into v_num_rows
                from   wf_tokens
                where  case_id = finished_p.case_id
                and    state in ('free', 'locked');
    
                if v_num_rows > 1 then 
                    raise_application_error(-20000, 'The workflow net is misconstructed: Some parallel executions have not finished.');
                end if;
    
                /* Consume that token */
                select token_id into v_token_id
                from   wf_tokens
                where  case_id = finished_p.case_id
                and    state in ('free', 'locked');

                consume_token(
                    case_id => finished_p.case_id,
                    place_key => 'end',
                    journal_id => finished_p.journal_id
                );

                update wf_cases 
                set    state = 'finished' 
                where  case_id = finished_p.case_id;

                /* Add an extra entry to the journal */
                v_journal_id := journal_entry.new(
                    object_id => finished_p.case_id,
                    action => 'case finish',
                    action_pretty => 'Case finished'
                );

                return 't';
            end if;
        end if;
    end finished_p;



    /* This procedure should be scheduled to run as a dbms_job. */
    procedure sweep_timed_transitions 
    is
        cursor timed_transitions_to_fire is
            select t.task_id, t.case_id, tr.transition_name
            from   wf_tasks t, wf_transitions tr
            where  trigger_time <= sysdate
            and    state = 'enabled'
            and    tr.workflow_key = t.workflow_key
            and    tr.transition_key = t.transition_key;
        v_journal_id number;
    begin
        for trans_rec in timed_transitions_to_fire loop
 
            /* Insert an entry to the journal so people will know it fired */

            v_journal_id := journal_entry.new(
                object_id => trans_rec.case_id, 
                action =>  'task '||trans_rec.task_id|| ' fire time',
                action_pretty =>  trans_rec.transition_name || ' automatically finished',
                msg => 'Timed transition fired.'
            );
        
            /* Fire the transition */

            fire_transition_internal(
                task_id => trans_rec.task_id,
                journal_id => v_journal_id
            );

            /* Update the workflow internal state */

            sweep_automatic_transitions(
                case_id => trans_rec.case_id,
                journal_id => v_journal_id
            );

        end loop;
    end sweep_timed_transitions;


    /* This procedure should be scheduled to run as a dbms_job. */
    procedure sweep_hold_timeout 
    is
        cursor tasks_to_cancel is
            select t.task_id, t.case_id, tr.transition_name
            from   wf_tasks t, wf_transitions tr
            where  hold_timeout <= sysdate
            and    state = 'started'
            and    tr.workflow_key = t.workflow_key
            and    tr.transition_key = t.transition_key;
        v_journal_id number;
    begin
        for task_rec in tasks_to_cancel loop
 
            /* Insert an entry to the journal so people will know it was canceled */

            v_journal_id := journal_entry.new(
                object_id => task_rec.case_id, 
                action => 'task '||task_rec.task_id||' cancel timeout',
                action_pretty => task_rec.transition_name || ' timed out', 
                msg => 'The user''s hold on the task timed out and the task was automatically canceled'
            );


            /* Cancel the task */

            cancel_task(
                task_id => task_rec.task_id,
                journal_id => v_journal_id
            );

        end loop;
    end sweep_hold_timeout;




    procedure notify_assignee(
        task_id         in wf_tasks.task_id%TYPE,
        user_id         in users.user_id%TYPE,
        callback        in wf_context_transition_info.notification_callback%TYPE,
        custom_arg      in wf_context_transition_info.notification_custom_arg%TYPE
    )
    is
        v_deadline_pretty varchar2(400);
        v_object_name varchar2(4000);
        v_transition_key wf_transitions.transition_key%TYPE;
        v_transition_name wf_transitions.transition_name%TYPE;
        v_party_from parties.party_id%TYPE;
        v_party_to parties.party_id%TYPE;
        v_subject varchar2(4000);
        v_body varchar2(4000);
        v_request_id integer;
        v_workflow_url varchar2(400);
        cursor cr_principal is
          select wfi.principal_party
            from wf_context_workflow_info wfi, wf_tasks ta, wf_cases c
           where ta.task_id = notify_assignee.task_id
             and c.case_id = ta.case_id
             and wfi.workflow_key = c.workflow_key
             and wfi.context_key = c.context_key;
    begin
        select to_char(ta.deadline,'Mon fmDDfm, YYYY HH24:MI:SS'),
               acs_object.name(c.object_id),
               tr.transition_key,
               tr.transition_name
          into v_deadline_pretty,
               v_object_name, 
               v_transition_key,
               v_transition_name
          from wf_tasks ta, wf_transitions tr, wf_cases c
         where ta.task_id = notify_assignee.task_id
           and c.case_id = ta.case_id
           and tr.workflow_key = c.workflow_key
           and tr.transition_key = ta.transition_key;

        select apm.get_value(p.package_id,'SystemURL') || site_node.url(s.node_id)
          into v_workflow_url
          from site_nodes s, 
               apm_packages a,
               (select package_id
                from apm_packages 
                where package_key = 'acs-kernel') p
         where s.object_id = a.package_id 
           and a.package_key = 'acs-workflow';

        /* Mail sent from */
        open cr_principal;
        fetch cr_principal into v_party_from;
        if cr_principal%NOTFOUND then
            v_party_from := -1;
        end if;

        /* Subject */
        v_subject := 'Assignment: '||v_transition_name||' ('||v_object_name||')';

        /* Body */
        v_body := 'You have been assigned to a task.
'||'
Case        : '||v_object_name||'
Task        : '||v_transition_name||'
';

        if v_deadline_pretty != '' then
            v_body := v_body||'Deadline    : '||v_deadline_pretty||'
';
        end if;

	v_body := v_body ||'Task website: '||v_workflow_url||'task?task_id='||notify_assignee.task_id||'
';

        /* The notifications should really be sent from the application server layer, not from the database */
    
        if notify_assignee.callback is not null then
            execute immediate 'begin '||notify_assignee.callback||'(:1, :2, :3, :4, :5, :6); end;'
                using in notify_assignee.task_id,
                      in notify_assignee.custom_arg,
                      in notify_assignee.user_id,
                      in out v_party_from,
                      in out v_subject,
                      in out v_body;
        else
            v_request_id := acs_mail_nt.post_request (       
                party_from => v_party_from,
                party_to => notify_assignee.user_id,
                expand_group => 'f' ,
                subject => v_subject,
                message => v_body
            );
        end if;

    end notify_assignee;



    /*
     * This procedure synchronizes the actually enabled transitions 
     * (i.e., the ones where tokens are currently present on the
     * input places), with the cached version of that information, 
     * in wf_tasks.
     * It is entirely idempotent and will at any given time sync up with
     * the actual state of the workflow (as per the tokens), so we don't
     * need to pass in a journal_id.
     */
    procedure enable_transitions (
        case_id         in number
    ) is
        cursor tasks_to_create is
            select et.transition_key,
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
              from wf_enabled_transitions et, wf_context_role_info cr
             where et.case_id = enable_transitions.case_id
               and et.workflow_key = cr.workflow_key (+)
               and et.role_key = cr.role_key (+)
               and not exists (select 1 from wf_tasks 
                               where case_id = enable_transitions.case_id
                               and   transition_key = et.transition_key
                               and   state in ('enabled', 'started'));
        v_task_id number;
        v_workflow_key varchar2(100);
        v_trigger_time date;
        v_deadline_date date;
        v_party_from integer;
        v_subject varchar2(500);
        v_body varchar2(4000);
        v_num_assigned number;
        request_id number;
        cursor assignees_cur is
            select distinct u.user_id
            from   wf_task_assignments tasgn,
                   party_approved_member_map m,
                   users u
            where  tasgn.task_id = v_task_id
            and    m.party_id = tasgn.party_id
            and    u.user_id = m.member_id;
    begin
        select workflow_key into v_workflow_key 
        from   wf_cases 
        where  case_id = enable_transitions.case_id;
    
        /* we mark tasks overridden if they were once enabled, but are no longer so */

        update wf_tasks 
        set    state = 'overridden',
               overridden_date = sysdate
        where  case_id = enable_transitions.case_id 
        and    state = 'enabled'
        and    transition_key not in 
            (select transition_key 
             from wf_enabled_transitions 
             where case_id = enable_transitions.case_id);
    

        /* insert a task for the transitions that are enabled but have no task row */

        for trans_rec in tasks_to_create loop

            v_trigger_time := null;
            v_deadline_date := null;

            if trans_rec.trigger_type = 'user' then
                v_deadline_date := get_task_deadline(
                    callback => trans_rec.deadline_callback, 
                    custom_arg => trans_rec.deadline_custom_arg,
                    attribute_name => trans_rec.deadline_attribute_name,
                    case_id => enable_transitions.case_id, 
                    transition_key => trans_rec.transition_key
                );
            elsif trans_rec.trigger_type = 'time' then
                v_trigger_time := execute_time_callback(trans_rec.time_callback, 
                    trans_rec.time_custom_arg,
                    enable_transitions.case_id, trans_rec.transition_key);
            end if;

            /* we're ready to insert the row */
            select wf_task_id_seq.nextval into v_task_id from dual;

            insert into wf_tasks (
                task_id, case_id, workflow_key, transition_key, 
                deadline, trigger_time, estimated_minutes
            ) values (
                v_task_id, enable_transitions.case_id, v_workflow_key, 
                trans_rec.transition_key,
                v_deadline_date, v_trigger_time, trans_rec.estimated_minutes
            );
            
            set_task_assignments(
                task_id => v_task_id,
                callback => trans_rec.assignment_callback,
                custom_arg => trans_rec.assignment_custom_arg
            );

            /* Execute the transition enabled callback */
            execute_transition_callback(
                callback => trans_rec.enable_callback, 
                custom_arg => trans_rec.enable_custom_arg,
                case_id => enable_transitions.case_id, 
                transition_key => trans_rec.transition_key
            );

            select count(*) into v_num_assigned
            from   wf_task_assignments
            where  task_id = v_task_id;

            if v_num_assigned = 0 then
                execute_unassigned_callback (
                    callback => trans_rec.unassigned_callback,
                    task_id => v_task_id,
                    custom_arg => trans_rec.unassigned_custom_arg
                );
            end if;

        end loop;
    end enable_transitions;


    procedure fire_transition_internal (
        task_id         in number,
        journal_id      in number
    ) is
        v_case_id number;
        v_state varchar2(40);
        v_transition_key varchar2(100);
        v_workflow_key varchar2(100);
        v_place_key varchar2(100);
        v_direction varchar2(3);
        v_guard_happy_p char(1);
        v_fire_callback varchar2(100);
        v_fire_custom_arg varchar2(4000);
        v_found_happy_guard char(1);
        v_locked_task_id number;
    begin
        select t.case_id, t.state, t.workflow_key, t.transition_key, ti.fire_callback, ti.fire_custom_arg
        into   v_case_id, v_state, v_workflow_key, v_transition_key, v_fire_callback, v_fire_custom_arg
        from   wf_tasks t, wf_cases c, wf_transition_info ti
        where  t.task_id = fire_transition_internal.task_id
        and    c.case_id = t.case_id
        and    ti.context_key = c.context_key
        and    ti.workflow_key = c.workflow_key
        and    ti.transition_key = t.transition_key;

        /* Check that the state is either started or enabled */

        if v_state = 'enabled' then 
            v_locked_task_id := null;
        elsif v_state = 'started' then
            v_locked_task_id := fire_transition_internal.task_id;
        else 
            raise_application_error(-20000, 'Can''t fire the transition if it''s not in state enabled or started');
        end if;
        

        /* Mark the task finished */

        update wf_tasks
        set    state = 'finished',
               finished_date = sysdate
        where  task_id = fire_transition_internal.task_id;


        /* Consume the tokens */

        for place_rec in input_places(v_workflow_key, v_transition_key) loop 
            consume_token(
                case_id => v_case_id,
                place_key => place_rec.place_key,
                journal_id => fire_transition_internal.journal_id,
                task_id => v_locked_task_id
             );
        end loop;

    
        /* Spit out new tokens in the output places */

        v_found_happy_guard := 'f';
        for place_rec in output_places(v_workflow_key, v_transition_key) loop
            v_place_key := place_rec.place_key;
            v_direction := place_rec.direction;
            v_guard_happy_p := evaluate_guard(
                callback => place_rec.guard_callback, 
                custom_arg => place_rec.guard_custom_arg,
                case_id => v_case_id, 
                workflow_key => v_workflow_key, 
                transition_key => v_transition_key, 
                place_key => v_place_key, 
                direction => v_direction
            );
    
            if v_guard_happy_p = 't' then
                v_found_happy_guard := 't';
                add_token(
                    case_id => v_case_id, 
                    place_key => place_rec.place_key,
                    journal_id => fire_transition_internal.journal_id
                );
            end if;
        end loop;


        /* If we didn't find any happy guards, look for arcs with the special hash (#) guard */

        if v_found_happy_guard = 'f' then
            for place_rec in (
                select place_key
                from   wf_transition_places tp
                where  tp.workflow_key = v_workflow_key
                and    tp.transition_key = v_transition_key
                and    tp.direction = 'out'
                and    tp.guard_callback = '#') 
            loop
                add_token(
                    case_id => v_case_id, 
                    place_key => place_rec.place_key,
                    journal_id => fire_transition_internal.journal_id
                );
            end loop;
        end if;


        /* Execute the transition fire callback */

        execute_transition_callback(
            callback => v_fire_callback, 
            custom_arg => v_fire_custom_arg, 
            case_id => v_case_id, 
            transition_key => v_transition_key
        );
    end fire_transition_internal;
    
    

    /* A small helper to make sure we're in the state we expect to be */
    procedure ensure_task_in_state (
        task_id         in number,
        state           in varchar2
    ) is 
        v_count number;
    begin
        select decode(count(*),0,0,1) into v_count
        from   wf_tasks 
        where  task_id = ensure_task_in_state.task_id
        and    state = ensure_task_in_state.state;
    
        if v_count != 1 then
            raise_application_error(-20000, 'The task '|| ensure_task_in_state.task_id || ' is not in state ''' || ensure_task_in_state.state || '''');
        end if;
    end ensure_task_in_state;
    
        

    /* Marks a task started and reserves one token from each input place */
    procedure start_task(
        task_id         in number,
        user_id         in number,
        journal_id      in number
    ) is
        v_case_id number;
        v_workflow_key wf_workflows.workflow_key%TYPE;
        v_transition_key varchar2(100);
        v_hold_timeout_callback varchar2(100);
        v_hold_timeout_custom_arg varchar2(4000);
        v_hold_timeout date;
    begin
        ensure_task_in_state(task_id => start_task.task_id, state => 'enabled');
    
        select t.case_id, t.workflow_key, t.transition_key, ti.hold_timeout_callback, ti.hold_timeout_custom_arg 
        into   v_case_id, v_workflow_key, v_transition_key, v_hold_timeout_callback, v_hold_timeout_custom_arg
        from   wf_tasks t, wf_cases c, wf_transition_info ti
        where  t.task_id = start_task.task_id
        and    c.case_id = t.case_id
        and    ti.context_key = c.context_key
        and    ti.workflow_key = t.workflow_key
        and    ti.transition_key = t.transition_key;

        v_hold_timeout := execute_hold_timeout_callback(v_hold_timeout_callback, 
            v_hold_timeout_custom_arg, v_case_id, v_transition_key);

        /* Mark it started */

        update wf_tasks 
        set    state = 'started', 
               started_date = sysdate,
               holding_user = start_task.user_id, 
               hold_timeout = v_hold_timeout
        where task_id = start_task.task_id;
    
        
        /* Reserve one token from each input place */

        for place_rec in input_places(v_workflow_key,v_transition_key) loop
            lock_token( 
                case_id => v_case_id,
                place_key => place_rec.place_key,
                journal_id => start_task.journal_id,
                task_id => start_task.task_id
            );
        end loop;
    end start_task;
    

    /* Mark the task canceled and release the reserved tokens */
    procedure cancel_task(
        task_id         in number,
        journal_id      in number
    ) 
    is
        v_case_id number;
    begin
        ensure_task_in_state(task_id => cancel_task.task_id, state => 'started');
        select case_id into v_case_id 
        from wf_tasks 
        where task_id = cancel_task.task_id;
    
        /* Mark the task canceled */

        update wf_tasks 
        set    state = 'canceled',
               canceled_date =  sysdate
        where  task_id = cancel_task.task_id;

    
        /* Release our reserved tokens */

        release_token(
            task_id => cancel_task.task_id,
            journal_id => cancel_task.journal_id
        );

        /* The workflow state has now changed, so we must run this */
        
        sweep_automatic_transitions(
            case_id => v_case_id,
            journal_id => cancel_task.journal_id
        );
    end cancel_task;
    

    /* Fire the transition */
    procedure finish_task (
        task_id         in number,      
        journal_id      in number
    ) 
    is
        v_case_id number;
    begin
        select case_id into v_case_id
        from   wf_tasks
        where  task_id = finish_task.task_id;

        fire_transition_internal(
            task_id => finish_task.task_id,
            journal_id => finish_task.journal_id
        );

        sweep_automatic_transitions(
            case_id => v_case_id,
            journal_id => finish_task.journal_id
        );
    end finish_task;

    function get_task_id (
        case_id         in wf_cases.case_id%TYPE,
        transition_key  in wf_transitions.transition_key%TYPE
    ) return wf_tasks.task_id%TYPE
    is
        v_task_id number;
    begin

        select task_id into v_task_id
        from wf_tasks
        where case_id = get_task_id.case_id and
          transition_key = get_task_id.transition_key;

        return v_task_id;

        exception when no_data_found then
          raise_application_error(-20000, 'Case ' || case_id || 'has no transition with key ' || transition_key);

    end get_task_id;

end workflow_case;
/
show errors;
