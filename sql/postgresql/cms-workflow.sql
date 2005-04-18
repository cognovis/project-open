--/** This package is used to manipulate the publishing workflow for CMS
--    @author Michael Pih
--*/




-- create or replace package content_workflow
-- as
-- 
--   function is_overdue (
--   --/** Determines if the workflow task is overdue
--   --    @author Michael Pih
--   --    @param task_id            The task id
--   --    @return 't' if the deadline > sysdate, 'f' otherwise
--   --*/
--     v_task_id in wf_tasks.task_id%TYPE
--   ) return char;
-- 
-- 
--   function is_overdue (
--   --/** Determines if the workflow transition (task) is overdue
--   --    @author Michael Pih
--   --    @param case_id            The case id
--   --    @param transition_key     The transition key
--   --    @return 't' if the deadline >  sysdate, 'f' otherwise
--   --*/
--     case_id		in wf_cases.case_id%TYPE,
--     transition_key	in wf_transitions.transition_key%TYPE
--   ) return char;
-- 
-- 
--   function get_holding_user_name(
--   --/** Gets the name of the user who is currently holding this task
--   --    @author Michael Pih
--   --    @param task_id            The task id
--   --    @return name of the user who holds the task, otherwise NULL
--   --*/
--     v_task_id in wf_tasks.task_id%TYPE
--   ) return varchar2;
-- 
-- 
--   function get_first_place
--   --/** Gets the first place in the workflow (determined by sort order)
--   --    @author Michael Pih
--   --    @return the first place in the workflow
--   --*/
--   return wf_places.place_key%TYPE;
-- 
-- 
--   function get_this_place(
--   --/** Gets the current place in the workflow given the current transition
--   --    @author Michael Pih
--   --    @param transition_key The transition
--   --    @return the current place in the workflow
--   --*/
--     transition_key	in wf_transitions.transition_key%TYPE
--   ) return wf_places.place_key%TYPE;
-- 
-- 
--   function get_next_place(
--   --/** Gets the next place given a transition key (determined by sort order).
--   --    Throws an error if there is no next place.
--   --    @author Michael Pih
--   --    @param  transition_key The transition
--   --    @return the next place in the workflow
--   --*/
--     transition_key	in wf_transitions.transition_key%TYPE
--   ) return wf_places.place_key%TYPE;
-- 
-- 
--   function get_previous_place(
--   --/** Gets the previous place given a transition key 
--   --    (determined by sort order).
--   --    Throws an error if there is no previous place.
--   --    @author Michael Pih
--   --    @param  transition_key The transition
--   --    @return the previous place in the workflow
--   --*/
--     transition_key	in wf_transitions.transition_key%TYPE
--   ) return wf_places.place_key%TYPE;
-- 
-- 
--   procedure checkout (
--   --/** Checks out a task
--   --    @author Michael Pih
--   --    @param task_id		The task_id
--   --    @param hold_timeout     How long the user expects to hold this task
--   --    @param user_id		The user checking out the task
--   --    @param ip_address	The user's IP address (for auditing)
--   --	@param msg		Comments concerning checkout
--   --*/
--     task_id		in wf_tasks.task_id%TYPE,
--     hold_timeout	in wf_tasks.hold_timeout%TYPE default null,
--     user_id		in acs_objects.creation_user%TYPE,
--     ip_address		in acs_objects.creation_ip%TYPE,
--     msg			in varchar
--   );
-- 
-- 
--   procedure checkin (
--   --/** Checks in a task that the user is holding.  Throws an error
--   --    if the task is not checked out already or if the task is checked
--   --    out by another user.
--   --    @author Michael Pih
--   --    @param task_id		The task_id
--   --    @param user_id		The user checking in the task
--   --    @param ip_address	The IP address of the user
--   --    @param msg		Comment associated with checking the task in
--   --*/  
--     task_id		in wf_tasks.task_id%TYPE,
--     user_id		in acs_objects.creation_user%TYPE,
--     ip_address		in acs_objects.creation_ip%TYPE,
--     msg			in varchar
--   );
-- 
-- 
--   procedure approve(
--   --/** Finish a task
--   --    @author Michael Pih
--   --    @param task_id		The task_id
--   --    @param user_id		The user finishing the task
--   --    @param ip_address	The user's IP address (for auditing)
--   --	@param msg		Comments concerning finishing the task
--   --*/
--     task_id		in wf_tasks.task_id%TYPE,
--     user_id		in acs_objects.creation_user%TYPE,
--     ip_address		in acs_objects.creation_ip%TYPE,
--     msg			in varchar
--   );
-- 
-- 
--   procedure reject(
--   --/** Finish a task
--   --    @author Michael Pih
--   --    @param task_id		The task_id
--   --    @param user_id		The user finishing the task
--   --    @param ip_address	The user's IP address (for auditing)
--   --    @param transition_key	The transition the user wants to fall back to
--   --	@param msg		Comments concerning finishing the task
--   --*/
--     task_id		in wf_tasks.task_id%TYPE,
--     user_id		in acs_objects.creation_user%TYPE,
--     ip_address		in acs_objects.creation_ip%TYPE,
--     transition_key	in wf_transitions.transition_key%TYPE,
--     msg			in varchar
--   );
-- 
-- 
--   procedure notify_of_checkout(
--   --/** Helper procedure.
--   --    Fires notifications after stealing the lock on a task
--   --    @author Michael Pih
--   --    @param task_id			The task_id
--   --    @param holding_user_old		The user finishing the task
--   --    @param holding_user_new		The user's IP address (for auditing)
--   --	@param msg			Comments concerning stealing the task
--   --*/
--     task_id			in wf_tasks.task_id%TYPE,
--     holding_user_old		in wf_tasks.holding_user%TYPE,
--     holding_user_new		in wf_tasks.holding_user%TYPE,
--     msg				in varchar
--   );
-- 
-- 
--   function can_reject(
--   --/** Returns 't' if a task is rejectable by the user.
--   --    Otherwise returns 'f'
--   --    @author Michael Pih
--   --    @param task_id			The task_id
--   --    @param user_id			The user_id
--   --    @return 't' if the task can be rejected, 'f' otherwise
--   --*/    
--   task_id	in wf_tasks.task_id%TYPE,
--   user_id	in wf_tasks.holding_user%TYPE
--   ) return char;
-- 
-- 
-- 
--   function can_approve(
--   --/** Returns 't' if a task is approvable by the user.
--   --    Otherwise returns 'f'
--   --    @author Michael Pih
--   --    @param task_id			The task_id
--   --    @param user_id			The user_id
--   --    @return 't' if the task can be approved, 'f' otherwise
--   --*/    
--     task_id	in wf_tasks.task_id%TYPE,
--     user_id	in wf_tasks.holding_user%TYPE
--   ) return char;
-- 
-- 
--   function can_start(
--   --/** Returns 't' if a task can be checked out by the user.
--   --    Otherwise returns 'f'
--   --    @author Michael Pih
--   --    @param task_id			The task_id
--   --    @param user_id			The user_id
--   --    @return 't' if the task can be started, 'f' otherwise
--   --*/    
--     task_id	in wf_tasks.task_id%TYPE,
--     user_id	in wf_tasks.holding_user%TYPE
--   ) return char;
-- 
-- 
-- 
--   function approve_string(
--   --/** If the task is approvable, returns 'Approve' or if it is the first
--   --	task, then 'Finish'.  Otherwise returns null.
--   --    @author Michael Pih
--   --    @param task_id			The task_id
--   --    @param user_id			The user_id
--   --    @return 'Approve','Finish' or null
--   --*/    
--     task_id	in wf_tasks.task_id%TYPE,
--     user_id	in wf_tasks.holding_user%TYPE
--   ) return varchar2;
-- 
-- 
-- 
--   function count_finished_tasks(
--   --/** Gets the number of finished tasks for a given case.
--   --    @author Michael Pih
--   --    @param case_id			The case_id
--   --    @return the number of finished tasks for a given case
--   --*/    
--     case_id		in wf_cases.case_id%TYPE
--   ) return integer;
-- 
-- 
--   function count_unfinished_tasks(
--   --/** Gets the number of unfinished tasks for a given case
--   --    @author Michael Pih
--   --    @param case_id			The case_id
--   --    @return the number of unfinished tasks for a given case
--   --*/    
--     case_id		in wf_cases.case_id%TYPE
--   ) return integer;
-- 
-- 
--   function is_active (
--   --/** Determines whether a case transition is active
--   --    @author Michael Pih
--   --    @param case_id			The case_id
--   --	@param transition_key		The transition
--   --    @return 't' id that case transition is active, 'f' otherwise
--   --*/    
--     case_id	       in wf_cases.case_id%TYPE,
--     transition_key     in wf_transitions.transition_key%TYPE
--   ) return char;
-- 
-- 
--   function is_finished (
--   --/** Determines whether a case transition is finished
--   --    @author Michael Pih
--   --    @param case_id			The case_id
--   --	@param transition_key		The transition
--   --    @return 't' id that case transition is finished, 'f' otherwise
--   --*/    
--     case_id	       in wf_cases.case_id%TYPE,
--     transition_key     in wf_transitions.transition_key%TYPE
--   ) return char;
-- 
-- 
--   function is_checked_out (
--   --/** Determines whether a case transition is checked out
--   --    @author Michael Pih
--   --    @param case_id			The case_id
--   --	@param transition_key		The transition
--   --    @return 't' id that case transition is checked out, 'f' otherwise
--   --*/    
--     case_id	       in wf_cases.case_id%TYPE,
--     transition_key     in wf_transitions.transition_key%TYPE
--   ) return char;
-- 
-- 
--   function is_checked_out (
--   --/** Determines whether a case transition is checked out by a certain user
--   --    @author Michael Pih
--   --    @param case_id			The case_id
--   --	@param transition_key		The transition
--   --    @param user_id			The user
--   --    @return 't' id that case transition is checked out by the specified
--   --            user, 'f' otherwise
--   --*/    
--     case_id	       in wf_cases.case_id%TYPE,
--     transition_key     in wf_transitions.transition_key%TYPE,
--     user_id	       in wf_tasks.holding_user%TYPE
--   ) return char;
-- 
-- 
--   function get_status(
--   --/** Gets the status of the task.
--   --    @author Michael Pih
--   --    @param case_id			The case_id
--   --	@param transition_key		The transition
--   --    @return HTML-formatted status of the task, null otherwise
--   --*/        
--     case_id		in wf_cases.case_id%TYPE,
--     transition_key	in wf_transitions.transition_key%TYPE
--   ) return varchar2;
-- 
-- 
--   function can_touch (
--   --/** Returns 't' if a user has permission to touch an item
--   --    @author Michael Pih
--   --    @param item_id	The item
--   --	@param user_id  The user
--   --    @return 't' if a user has permission to touch an item, 'f' otherwise
--   --      An item is touchable if:
--   --      1) the user has admin privileges on the
--   --      2) a workflow exists, current task assigned to user, and
--   --          the task is not checked out
--   --*/ 
--     item_id	in cr_items.item_id%TYPE,
--     user_id     in users.user_id%TYPE
--   ) return char;
-- 
-- 
-- 
--   function unfinished_workflow_exists (
--   --/** Returns 't' if an unfinished (not cancelled) workflow exists
--   --    otherwise returns 'f'
--   --    @author Michael Pih
--   --    @param item_id	The item
--   --    @return 't' if a workflow case exists and is not in the 'finished' or
--   --            'canceled' state
--   --*/ 
--     item_id	in cr_items.item_id%TYPE
--   ) return char;
-- 
-- 
-- end content_workflow;

-- show errors





-- create or replace package body content_workflow 
-- function is_overdue
create or replace function content_workflow__is_overdue (integer)
returns boolean as '
declare
  p_task_id            alias for $1;  
begin

    -- FIXME: is dead.deadline supposed to be a date-only (e.g. no time)
    return 
      count(*) > 0
    from
      wf_tasks t, wf_case_deadlines dead
    where
      t.task_id = p_task_id
    and
      t.case_id = dead.case_id
    and
      t.transition_key = dead.transition_key
    and
      t.workflow_key = dead.workflow_key
    and
      dead.deadline is not null
    and
      dead.deadline < date_trunc(''day'',now());
   
end;' language 'plpgsql';


-- function is_overdue
create or replace function content_workflow__is_overdue (integer,varchar)
returns boolean as '
declare
  p_case_id                        alias for $1;  
  p_transition_key                 alias for $2;  
begin
    return 
      count(*) > 0
    from
      wf_case_deadlines dead
    where
      case_id = p_case_id
    and
      transition_key = p_transition_key
    and
      deadline is not null
    and
      deadline < date_trunc(''day'',now())
    and
      content_workflow__is_finished(p_case_id, p_transition_key) = ''f'';
   
end;' language 'plpgsql';


-- function get_holding_user_name
create or replace function content_workflow__get_holding_user_name (integer)
returns varchar as '
declare
  p_task_id                        alias for $1;  
  v_name                           varchar;  
begin

    select
      first_names || '' '' || last_name
    into
      v_name
    from
      persons p, wf_tasks t
    where
      t.holding_user = p.person_id
    and
      t.task_id = p_task_id;

    return v_name;
   
end;' language 'plpgsql';



create or replace function content_workflow__get_first_place() returns varchar as '
declare
    v_first_place wf_places.place_key%TYPE;
begin

    select
      place_key into v_first_place
    from
      wf_places w
    where
      workflow_key = ''publishing_wf''
    and
      sort_order = (select 
                      min(sort_order) 
		    from 
		      wf_places
		    where
		      workflow_key = w.workflow_key);

    return v_first_place;

end;' language 'plpgsql';

-- function get_this_place
create or replace function content_workflow__get_this_place (varchar)
returns varchar as '
declare
  p_transition_key                 alias for $1;  
  v_this_place                     wf_places.place_key%TYPE;
begin

    select 
      place_key into v_this_place
    from 
      wf_arcs
    where
      transition_key = p_transition_key
    and
      workflow_key = ''publishing_wf''
    and
      direction = ''in'';
    

    if NOT FOUND then
        raise EXCEPTION ''-20000:  Bad transition key %'', p_transition_key;
    end if;

    return v_this_place;
     
end;' language 'plpgsql';


-- function get_next_place
create or replace function content_workflow__get_next_place (varchar)
returns varchar as '
declare
  p_transition_key                 alias for $1;  
  v_next_place                     wf_places.place_key%TYPE;
begin

     select 
        there.place_key 
      into
        v_next_place
      from
        wf_places here, wf_places there
      where
        here.workflow_key = ''publishing_wf''
      and
        here.workflow_key = there.workflow_key
      and
        here.place_key = content_workflow__get_this_place( p_transition_key )
      and
        there.sort_order > here.sort_order
      order by 
        there.sort_order
      limit 1;

    if NOT FOUND then
      raise EXCEPTION ''-20000: content_workflow.get_next_place - No next place - Dead End'';
    end if;
 
    return v_next_place;
  
end;' language 'plpgsql';


-- function get_previous_place
create or replace function content_workflow__get_previous_place (varchar)
returns varchar as '
declare
  p_transition_key                 alias for $1;  
  v_previous_place                 wf_places.place_key%TYPE;
begin

      select 
        there.place_key 
      into 
        v_previous_place
      from
        wf_places here, wf_places there
      where
        here.workflow_key = ''publishing_wf''
      and
        here.workflow_key = there.workflow_key
      and
        here.place_key = content_workflow__get_this_place( p_transition_key )
      and
        there.sort_order < here.sort_order
      order by 
        there.sort_order desc
      limit 1;

    if NOT FOUND then 
      raise EXCEPTION ''-20000: content_workflow.get_previous_place - No previous place - Dead End'';
    end if;

    return v_previous_place;
   
end;' language 'plpgsql';


-- procedure checkout
create or replace function content_workflow__checkout (integer,timestamptz,integer,varchar,varchar)
returns integer as '
declare
  p_task_id                        alias for $1;  
  p_hold_timeout                   alias for $2;  -- default null  
  p_user_id                        alias for $3;  
  p_ip_address                     alias for $4;  
  p_msg                            alias for $5;  
  v_task_state                     wf_tasks.state%TYPE;
  v_holding_user                   wf_tasks.holding_user%TYPE;
  v_journal_id                     integer;        
  v_transition_key                 wf_transitions.transition_key%TYPE;
  v_this_place                     wf_places.place_key%TYPE;
begin
    
    -- find out who is holding the task right now
    select
      state, holding_user, transition_key
     into 
       v_task_state, v_holding_user, v_transition_key
    from
      wf_tasks
    where
      task_id = p_task_id;
   
    -- someone else has already holds this task
    -- we need to check in the task as the other person before 
    --    this user can check it out
    if v_task_state = ''started'' and v_holding_user is not null 
       and v_holding_user != p_user_id then

      -- need to manually update the state otherwise a new task is created
      update wf_tasks
        set state = ''enabled'',
	holding_user = null,
	hold_timeout = null
        where task_id = p_task_id;

      v_task_state := ''enabled'';
    end if;

    -- actually check out the item 
    -- (start the task but do not change next_place)
    if v_task_state = ''enabled'' then

      v_journal_id := workflow_case__begin_task_action(
          p_task_id,
          ''start'',
          p_ip_address,
          p_user_id,
          p_msg
      ); 

      v_this_place := content_workflow__get_this_place( v_transition_key );

      PERFORM workflow_case__set_attribute_value(
          v_journal_id,
	  ''next_place'',
	  v_transition_key
      );

      PERFORM workflow_case__end_task_action(
          v_journal_id,
          ''start'',
          p_task_id
      );

      -- change the holding user and hold timeout
      update wf_tasks
        set hold_timeout = p_hold_timeout,
        holding_user = p_user_id
        where task_id = p_task_id;

      if v_holding_user is not null and 
        v_holding_user != p_user_id then

        -- send a notification
        PERFORM content_workflow__notify_of_checkout(
            p_task_id,
	    v_holding_user,
	    p_user_id,
	    p_msg
        );
      end if;

    else
      raise EXCEPTION ''-20000: Cannot check out this task because it is in an invalid state %'', v_task_state;
    end if;

    return 0; 
end;' language 'plpgsql';


-- procedure checkin
create or replace function content_workflow__checkin (integer,integer,varchar,varchar)
returns integer as '
declare
  p_task_id                        alias for $1;  
  p_user_id                        alias for $2;  
  p_ip_address                     alias for $3;  
  p_msg                            alias for $4;  
  v_task_state                     wf_tasks.state%TYPE;
  v_holding_user                   wf_tasks.holding_user%TYPE;
  v_journal_id                     integer;        
  v_this_place                     wf_places.place_key%TYPE;
  v_transition_key                 wf_transitions.transition_key%TYPE;
begin

    -- find out who is holding the task right now
    select
      state, holding_user, transition_key
    into 
      v_task_state, v_holding_user, v_transition_key
    from
      wf_tasks
    where
      task_id = p_task_id;

    if v_task_state = ''started'' and v_holding_user = p_user_id then

      v_journal_id := workflow_case__begin_task_action(
          p_task_id,
	  ''finish'',
 	  p_ip_address,
	  p_user_id,
	  p_msg
      );

      v_this_place := content_workflow__get_this_place( v_transition_key );

      PERFORM workflow_case__set_attribute_value(
          v_journal_id,
	  ''next_place'',
	  v_this_place
      );

      PERFORM workflow_case__end_task_action(
          v_journal_id,
	  ''finish'',
	  p_task_id
      );


    else if v_task_state != ''started'' then
      raise EXCEPTION '' -20000:  Cannot chack in this task because it is in an invalid state %'', v_task_state;
    else
      raise EXCEPTION '' -20000: Cannot check in this task because user_id % is not the holding user'', p_user_id;
    end if; end if;

    return 0; 
end;' language 'plpgsql';


-- procedure approve
create or replace function content_workflow__approve (integer,integer,varchar,varchar)
returns integer as '
declare
  p_task_id                        alias for $1;  
  p_user_id                        alias for $2;  
  p_ip_address                     alias for $3;  
  p_msg                            alias for $4;  
  v_task_state                     wf_tasks.state%TYPE;
  v_holding_user                   wf_tasks.holding_user%TYPE;
  v_journal_id                     integer;        
  v_transition_key                 wf_transitions.transition_key%TYPE;
  v_next_place                     wf_places.place_key%TYPE;
begin

    -- find out who is holding the task right now
    select
      state, holding_user, transition_key
    into 
      v_task_state, v_holding_user, v_transition_key
    from
      wf_tasks
    where
      task_id = p_task_id;

    if v_task_state = ''started'' and v_holding_user != p_user_id then

      raise EXCEPTION '' -20000: content_workflow.approve - Could not approve task because this task is checked out by someone else %'', v_holding_user;

    else if v_task_state != ''started'' and v_task_state != ''enabled'' then
      raise EXCEPTION '' -20000: content_workflow.approve - Could not approve task because this task is in an invalid state %'', v_task_state;

    -- user is allowed to finish the task
    else

      -- we need to checkout the task first
      if v_task_state = ''enabled'' then
        PERFORM content_workflow__checkout(
	    p_task_id,	
	    null,
	    p_user_id,
	    p_ip_address,
	    p_msg
        );
      end if;

      v_journal_id := workflow_case__begin_task_action(
          p_task_id,
          ''finish'',
          p_ip_address,
          p_user_id,
          p_msg
      ); 

      v_next_place := content_workflow__get_next_place(
          v_transition_key
      );

      PERFORM workflow_case__set_attribute_value(
          v_journal_id,
	  ''next_place'',
	  v_next_place
      );

      PERFORM workflow_case__end_task_action(
          v_journal_id,
          ''finish'',
          p_task_id
      );

    end if; end if;

    return 0; 
end;' language 'plpgsql';


-- procedure reject
create or replace function content_workflow__reject (integer,integer,varchar,varchar,varchar)
returns integer as '
declare
  p_task_id                        alias for $1;  
  p_user_id                        alias for $2;  
  p_ip_address                     alias for $3;  
  p_transition_key                 alias for $4;  
  p_msg                            alias for $5;  
  v_task_state                     wf_tasks.state%TYPE;
  v_holding_user                   wf_tasks.holding_user%TYPE;
  v_transition_key                 wf_transitions.transition_key%TYPE;
  v_journal_id                     integer;        
  v_sanity_check                   integer;       
  v_previous_place                 wf_places.place_key%TYPE;
begin

    -- find out who is holding the task right now
    select
      state, holding_user, transition_key
    into 
      v_task_state, v_holding_user, v_transition_key
    from
      wf_tasks
    where
      task_id = p_task_id;

    -- do a quick sanity check
    -- make sure the desired transition is accessible from this transition
    select 
      count(1) into v_sanity_check
    from 
      wf_arcs out, wf_arcs dest
    where 
      out.workflow_key = ''publishing_wf''
   and
      out.workflow_key = dest.workflow_key
    and
      out.direction = ''out'' 
    and 
      dest.direction = ''in''
    and
      out.transition_key = v_transition_key
    and
      dest.transition_key = p_transition_key
    and
      p_transition_key != v_transition_key
    and
      -- make sure the arcs are connected
      out.place_key = dest.place_key;


    if v_sanity_check = 0 then
      raise EXCEPTION '' -20000: content_workflow.reject - Sanity check failed - invalid transition: %'', p_transition_key;
    end if;


    if v_task_state = ''started'' and v_holding_user != p_user_id then
      raise EXCEPTION '' -20000: content_workflow.reject - Could not reject task because this task is checked out by someone else %'', v_holding_user;
    else if v_task_state != ''started'' and v_task_state != ''enabled'' then
      raise EXCEPTION '' -20000: content_workflow.approve - Could not reject task because this task is in an invalid state %'', v_task_state;
    else

      -- we need to start this task first
      if v_task_state = ''enabled'' then
        PERFORM content_workflow__checkout(
	    p_task_id,	
	    null,
	    p_user_id,
	    p_ip_address,
	    p_msg
        );

      end if;


      -- ok to reject this task
      v_journal_id := workflow_case__begin_task_action(
          p_task_id,
          ''finish'',
          p_ip_address,
          p_user_id,
          p_msg
      ); 

      v_previous_place := content_workflow__get_this_place(
          p_transition_key
      );

      PERFORM workflow_case__set_attribute_value(
          v_journal_id,
	  ''next_place'',
	  v_previous_place
      );

      PERFORM workflow_case__end_task_action(
          v_journal_id,
          ''finish'',
          p_task_id
      );

    end if; end if;

    return 0; 
end;' language 'plpgsql';


-- procedure notify_of_checkout
create or replace function content_workflow__notify_of_checkout (integer,integer,integer,varchar)
returns integer as '
declare
  p_task_id                        alias for $1;  
  p_holding_user_old               alias for $2;  
  p_holding_user_new               alias for $3;  
  p_msg                            alias for $4;  
  v_hold_user_old                  varchar(100);  
  v_hold_user_new                  varchar(100);  
  v_transition_name                wf_transitions.transition_name%TYPE;
--  v_request_id                     nt_requests.request_id%TYPE;
  v_item_name                      varchar(100);  
begin

    -- get the robbed users name
    select
      first_names || '' '' || last_name into v_hold_user_old
    from
      persons
    where
      person_id = p_holding_user_old;

    -- get the lock stealers name
    select
      first_names || '' '' || last_name into v_hold_user_new
    from
      persons
    where
      person_id = p_holding_user_new;

    -- get the item name and transition name
    select
      transition_name, content_item__get_title( c.object_id, ''f'' )
    into
      v_transition_name, v_item_name
    from
      wf_transitions trans, wf_tasks t, wf_cases c
    where
      trans.transition_key = t.transition_key
    and
      t.case_id = c.case_id
    and
      t.task_id = p_task_id;

    -- send out the request
    v_request_id := acs_mail_nt__post_request (
        p_holding_user_new,                               -- party_from
        p_holding_user_old,                               -- party_to
        ''f'',                                            -- expand_group
        v_hold_user_new || '' stole the lock for '' ||
		  v_transition_name || '' of '' || v_item_name,   -- subject
        ''Dear '' || v_hold_user_old || '',\n'' || p_msg, -- message
        0                                                 -- max_retries
    );

    return 0; 
end;' language 'plpgsql';


-- function can_reject
create or replace function content_workflow__can_reject (integer,integer)
returns boolean as '
declare
  p_task_id                        alias for $1;  
  p_user_id                        alias for $2;  
  v_transition_key                 wf_transitions.transition_key%TYPE;
begin

    return 
      count(*) > 0
    from
      wf_tasks
    where
      task_id = p_task_id
    and
      workflow_key = ''publishing_wf''
    and
      (state = ''enabled''
       or (state = ''started''
           and holding_user = p_user_id))
    and
      content_workflow__get_this_place(transition_key) !=
       content_workflow__get_first_place();
   
end;' language 'plpgsql';


-- function can_approve
create or replace function content_workflow__can_approve (integer,integer)
returns boolean as '
declare
  p_task_id                        alias for $1;  
  p_user_id                        alias for $2;  
begin

    return 
      count(*) > 0
    from
      wf_tasks
    where
      (state = ''enabled'' 
       or (state = ''started''
           and holding_user = p_user_id))
    and
      task_id = p_task_id
    and
      workflow_key = ''publishing_wf'';

end;' language 'plpgsql';


-- function can_start
create or replace function content_workflow__can_start (integer,integer)
returns boolean as '
declare
  p_task_id                        alias for $1;  
  p_user_id                        alias for $2;  
begin

    return 
      count(*) > 0
    from
      wf_tasks
    where
      (state = ''enabled'' 
       or (state = ''started''
           and holding_user != p_user_id))
    and
      task_id = p_task_id
    and
      workflow_key = ''publishing_wf'';
  
end;' language 'plpgsql';


-- function approve_string
create or replace function content_workflow__approve_string (integer,integer)
returns varchar as '
declare
  p_task_id                        alias for $1;  
  p_user_id                        alias for $2;  
  v_transition_key                 wf_transitions.transition_key%TYPE;
  v_approve_string                 varchar(10);   
begin

    if content_workflow__can_approve( 
      p_task_id, p_user_id ) = ''t'' then
      
      select
        transition_key into v_transition_key
      from
        wf_tasks
      where
        task_id = p_task_id;

      if content_workflow__get_this_place( v_transition_key ) = 
        content_workflow__get_first_place() then
	v_approve_string := ''Finish'';
      else
        v_approve_string := ''Approve'';
      end if;
      
    else
      v_approve_string := null;
    end if;

    return v_approve_string;
   
end;' language 'plpgsql';


-- function count_finished_tasks
create or replace function content_workflow__count_finished_tasks (integer)
returns integer as '
declare
  p_case_id                        alias for $1;  
begin

    return 
      count(before.place_key)
    from
      ( 
        select
          p.sort_order
        from
          wf_tasks t, wf_places p
        where
          t.workflow_key = ''publishing_wf''
        and
          t.workflow_key = p.workflow_key
        and
          p.place_key = content_workflow__get_this_place( t.transition_key )
        and
	  -- active task
          t.state in (''enabled'', ''started'')
        and
          t.case_id = p_case_id
      ) here,
      wf_places before
    where
      before.workflow_key = ''publishing_wf''
    and
      -- earlier transitions (tasks that have already been completed)
      before.sort_order < here.sort_order;

end;' language 'plpgsql';


-- function count_unfinished_tasks
create or replace function content_workflow__count_unfinished_tasks (integer)
returns integer as '
declare
  p_case_id                        alias for $1;  
  v_unfinished_tasks               integer;       
  v_already_finished_tasks         integer;       
  v_all_tasks                      integer;       
begin

    select
      count(transition_key) into v_all_tasks
    from
      wf_transitions
    where
      workflow_key = ''publishing_wf'';

    v_already_finished_tasks := content_workflow__count_finished_tasks(
        p_case_id
    );

    v_unfinished_tasks := v_all_tasks - v_already_finished_tasks;

    return coalesce(v_unfinished_tasks,0);
   
end;' language 'plpgsql';


-- function is_active
create or replace function content_workflow__is_active (integer,varchar)
returns boolean as '
declare
  p_case_id                        alias for $1;  
  p_transition_key                 alias for $2;  
begin

    return
      count(task_id) > 0
    from
      wf_tasks
    where
      transition_key = p_transition_key
    and
      case_id = p_case_id
    and
      state in (''started'',''enabled'');
   
end;' language 'plpgsql';


-- function is_finished
create or replace function content_workflow__is_finished (integer,varchar)
returns boolean as '
declare
  p_case_id                        alias for $1;  
  p_transition_key                 alias for $2;  
  v_finished_task                  record;
begin

    for v_finished_task in
      select
        trans.transition_key
      from
        wf_transitions trans, wf_places here, wf_places there, wf_tasks t
      where
        trans.workflow_key = ''publishing_wf''
      and
        here.workflow_key = there.workflow_key
      and
        here.workflow_key = trans.workflow_key
      and
        -- the task belongs to this case
        t.case_id = p_case_id
      and
        -- the task is active
        t.state in (''enabled'',''started'')
      and
        -- here is the place the case is currently at
        here.place_key = content_workflow__get_this_place(t.transition_key)
      and
        -- there is the place we are checking if it is finished
        there.place_key = content_workflow__get_this_place(
          trans.transition_key)
      and
        -- there needs to be done before here 
	-- (sort order determines task order)
        there.sort_order < here.sort_order
    LOOP
    
      -- check if this task has already been finished
      if p_transition_key = v_finished_task.transition_key then
        return ''t'';
      end if;
    end loop;

    return ''f'';
   
end;' language 'plpgsql';


-- function is_checked_out
create or replace function content_workflow__is_checked_out (integer,varchar)
returns boolean as '
declare
  p_case_id                        alias for $1;  
  p_transition_key                 alias for $2;  
begin
    return 
      count(*) > 0
    from
      wf_tasks t
    where
      workflow_key = ''publishing_wf''
    and
      case_id = p_case_id
    and
      transition_key = p_transition_key
    and
      state = ''started'';

end;' language 'plpgsql';


-- function is_checked_out
create or replace function content_workflow__is_checked_out (integer,varchar,integer)
returns boolean as '
declare
  p_case_id                        alias for $1;  
  p_transition_key                 alias for $2;  
  p_user_id                        alias for $3;  
begin
    return
      count(task_id) > 0
    from
      wf_tasks t
    where
      workflow_key = ''publishing_wf''
    and
      case_id = p_case_id
    and
      transition_key = p_transition_key
    and
      state = ''started''
    and
      holding_user = p_user_id;
   
end;' language 'plpgsql';


-- function get_status
create or replace function content_workflow__get_status (integer,varchar)
returns varchar as '
declare
  p_case_id                        alias for $1;  
  p_transition_key                 alias for $2;  
  v_status                         varchar(1000); 
  v_state                          wf_tasks.state%TYPE;
  v_holding_user                   wf_tasks.holding_user%TYPE;
  v_hold_timeout                   wf_tasks.hold_timeout%TYPE;
  v_enabled_timestamp              wf_tasks.enabled_date%TYPE;
  v_started_timestamp              wf_tasks.started_date%TYPE;
begin

    select
      state, holding_user, hold_timeout, enabled_date, started_date
    into
      v_state, v_holding_user, v_hold_timeout, v_enabled_date, v_started_date
    from
      wf_tasks
    where
      transition_key = p_transition_key
    and
      case_id = p_case_id
    and
      state in (''enabled'',''started'');

    v_status := ''<table><tr><td>Activated on '' || 
      to_char(v_enabled_date,''Mon. DD, YYYY HH24:MI:SS'') || 
      ''</td></tr>'';

    if v_state = ''started'' then

      v_status := v_status || 
        ''<tr><td><b>Checked Out</b> by <a href="user-tasks.acs?party_id='' ||
	v_holding_user || ''">'' || person__name(v_holding_user) ||
	''</a> on '' || to_char(v_started_date,''Mon. DD, YYYY HH24:MI:SS'') || 
	'' until '' ||
	to_char(v_hold_timeout,''Mon. DD, YYYY'') || ''</td></tr>'';
    end if;

    v_status := v_status || ''</table>'';    

    return v_status;
   
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


-- function unfinished_workflow_exists
create or replace function content_workflow__unfinished_workflow_exists (integer)
returns boolean as '
declare
  p_item_id                        alias for $1;  
begin

    return
      count(*) > 0
    from
      wf_cases
    where
      object_id = p_item_id
    and
      workflow_key = ''publishing_wf''
    and
      state in (''active'', ''created'', ''suspended'');
       
end;' language 'plpgsql';



-- show errors


