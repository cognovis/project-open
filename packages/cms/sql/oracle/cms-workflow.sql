--/** This package is used to manipulate the publishing workflow for CMS
--    @author Michael Pih
--*/





create or replace package content_workflow
as

  function is_overdue (
  --/** Determines if the workflow task is overdue
  --    @author Michael Pih
  --    @param task_id            The task id
  --    @return 't' if the deadline > sysdate, 'f' otherwise
  --*/
    v_task_id in wf_tasks.task_id%TYPE
  ) return char;


  function is_overdue (
  --/** Determines if the workflow transition (task) is overdue
  --    @author Michael Pih
  --    @param case_id            The case id
  --    @param transition_key     The transition key
  --    @return 't' if the deadline >  sysdate, 'f' otherwise
  --*/
    case_id		in wf_cases.case_id%TYPE,
    transition_key	in wf_transitions.transition_key%TYPE
  ) return char;


  function get_holding_user_name(
  --/** Gets the name of the user who is currently holding this task
  --    @author Michael Pih
  --    @param task_id            The task id
  --    @return name of the user who holds the task, otherwise NULL
  --*/
    v_task_id in wf_tasks.task_id%TYPE
  ) return varchar2;


  function get_first_place
  --/** Gets the first place in the workflow (determined by sort order)
  --    @author Michael Pih
  --    @return the first place in the workflow
  --*/
  return wf_places.place_key%TYPE;


  function get_this_place(
  --/** Gets the current place in the workflow given the current transition
  --    @author Michael Pih
  --    @param transition_key The transition
  --    @return the current place in the workflow
  --*/
    transition_key	in wf_transitions.transition_key%TYPE
  ) return wf_places.place_key%TYPE;


  function get_next_place(
  --/** Gets the next place given a transition key (determined by sort order).
  --    Throws an error if there is no next place.
  --    @author Michael Pih
  --    @param  transition_key The transition
  --    @return the next place in the workflow
  --*/
    transition_key	in wf_transitions.transition_key%TYPE
  ) return wf_places.place_key%TYPE;


  function get_previous_place(
  --/** Gets the previous place given a transition key 
  --    (determined by sort order).
  --    Throws an error if there is no previous place.
  --    @author Michael Pih
  --    @param  transition_key The transition
  --    @return the previous place in the workflow
  --*/
    transition_key	in wf_transitions.transition_key%TYPE
  ) return wf_places.place_key%TYPE;


  procedure checkout (
  --/** Checks out a task
  --    @author Michael Pih
  --    @param task_id		The task_id
  --    @param hold_timeout     How long the user expects to hold this task
  --    @param user_id		The user checking out the task
  --    @param ip_address	The user's IP address (for auditing)
  --	@param msg		Comments concerning checkout
  --*/
    task_id		in wf_tasks.task_id%TYPE,
    hold_timeout	in wf_tasks.hold_timeout%TYPE default null,
    user_id		in acs_objects.creation_user%TYPE,
    ip_address		in acs_objects.creation_ip%TYPE,
    msg			in varchar
  );


  procedure checkin (
  --/** Checks in a task that the user is holding.  Throws an error
  --    if the task is not checked out already or if the task is checked
  --    out by another user.
  --    @author Michael Pih
  --    @param task_id		The task_id
  --    @param user_id		The user checking in the task
  --    @param ip_address	The IP address of the user
  --    @param msg		Comment associated with checking the task in
  --*/  
    task_id		in wf_tasks.task_id%TYPE,
    user_id		in acs_objects.creation_user%TYPE,
    ip_address		in acs_objects.creation_ip%TYPE,
    msg			in varchar
  );


  procedure approve(
  --/** Finish a task
  --    @author Michael Pih
  --    @param task_id		The task_id
  --    @param user_id		The user finishing the task
  --    @param ip_address	The user's IP address (for auditing)
  --	@param msg		Comments concerning finishing the task
  --*/
    task_id		in wf_tasks.task_id%TYPE,
    user_id		in acs_objects.creation_user%TYPE,
    ip_address		in acs_objects.creation_ip%TYPE,
    msg			in varchar
  );


  procedure reject(
  --/** Finish a task
  --    @author Michael Pih
  --    @param task_id		The task_id
  --    @param user_id		The user finishing the task
  --    @param ip_address	The user's IP address (for auditing)
  --    @param transition_key	The transition the user wants to fall back to
  --	@param msg		Comments concerning finishing the task
  --*/
    task_id		in wf_tasks.task_id%TYPE,
    user_id		in acs_objects.creation_user%TYPE,
    ip_address		in acs_objects.creation_ip%TYPE,
    transition_key	in wf_transitions.transition_key%TYPE,
    msg			in varchar
  );


  procedure notify_of_checkout(
  --/** Helper procedure.
  --    Fires notifications after stealing the lock on a task
  --    @author Michael Pih
  --    @param task_id			The task_id
  --    @param holding_user_old		The user finishing the task
  --    @param holding_user_new		The user's IP address (for auditing)
  --	@param msg			Comments concerning stealing the task
  --*/
    task_id			in wf_tasks.task_id%TYPE,
    holding_user_old		in wf_tasks.holding_user%TYPE,
    holding_user_new		in wf_tasks.holding_user%TYPE,
    msg				in varchar
  );


  function can_reject(
  --/** Returns 't' if a task is rejectable by the user.
  --    Otherwise returns 'f'
  --    @author Michael Pih
  --    @param task_id			The task_id
  --    @param user_id			The user_id
  --    @return 't' if the task can be rejected, 'f' otherwise
  --*/    
  task_id	in wf_tasks.task_id%TYPE,
  user_id	in wf_tasks.holding_user%TYPE
  ) return char;



  function can_approve(
  --/** Returns 't' if a task is approvable by the user.
  --    Otherwise returns 'f'
  --    @author Michael Pih
  --    @param task_id			The task_id
  --    @param user_id			The user_id
  --    @return 't' if the task can be approved, 'f' otherwise
  --*/    
    task_id	in wf_tasks.task_id%TYPE,
    user_id	in wf_tasks.holding_user%TYPE
  ) return char;


  function can_start(
  --/** Returns 't' if a task can be checked out by the user.
  --    Otherwise returns 'f'
  --    @author Michael Pih
  --    @param task_id			The task_id
  --    @param user_id			The user_id
  --    @return 't' if the task can be started, 'f' otherwise
  --*/    
    task_id	in wf_tasks.task_id%TYPE,
    user_id	in wf_tasks.holding_user%TYPE
  ) return char;



  function approve_string(
  --/** If the task is approvable, returns 'Approve' or if it is the first
  --	task, then 'Finish'.  Otherwise returns null.
  --    @author Michael Pih
  --    @param task_id			The task_id
  --    @param user_id			The user_id
  --    @return 'Approve','Finish' or null
  --*/    
    task_id	in wf_tasks.task_id%TYPE,
    user_id	in wf_tasks.holding_user%TYPE
  ) return varchar2;



  function count_finished_tasks(
  --/** Gets the number of finished tasks for a given case.
  --    @author Michael Pih
  --    @param case_id			The case_id
  --    @return the number of finished tasks for a given case
  --*/    
    case_id		in wf_cases.case_id%TYPE
  ) return integer;


  function count_unfinished_tasks(
  --/** Gets the number of unfinished tasks for a given case
  --    @author Michael Pih
  --    @param case_id			The case_id
  --    @return the number of unfinished tasks for a given case
  --*/    
    case_id		in wf_cases.case_id%TYPE
  ) return integer;


  function is_active (
  --/** Determines whether a case transition is active
  --    @author Michael Pih
  --    @param case_id			The case_id
  --	@param transition_key		The transition
  --    @return 't' id that case transition is active, 'f' otherwise
  --*/    
    case_id	       in wf_cases.case_id%TYPE,
    transition_key     in wf_transitions.transition_key%TYPE
  ) return char;


  function is_finished (
  --/** Determines whether a case transition is finished
  --    @author Michael Pih
  --    @param case_id			The case_id
  --	@param transition_key		The transition
  --    @return 't' id that case transition is finished, 'f' otherwise
  --*/    
    case_id	       in wf_cases.case_id%TYPE,
    transition_key     in wf_transitions.transition_key%TYPE
  ) return char;


  function is_checked_out (
  --/** Determines whether a case transition is checked out
  --    @author Michael Pih
  --    @param case_id			The case_id
  --	@param transition_key		The transition
  --    @return 't' id that case transition is checked out, 'f' otherwise
  --*/    
    case_id	       in wf_cases.case_id%TYPE,
    transition_key     in wf_transitions.transition_key%TYPE
  ) return char;


  function is_checked_out (
  --/** Determines whether a case transition is checked out by a certain user
  --    @author Michael Pih
  --    @param case_id			The case_id
  --	@param transition_key		The transition
  --    @param user_id			The user
  --    @return 't' id that case transition is checked out by the specified
  --            user, 'f' otherwise
  --*/    
    case_id	       in wf_cases.case_id%TYPE,
    transition_key     in wf_transitions.transition_key%TYPE,
    user_id	       in wf_tasks.holding_user%TYPE
  ) return char;


  function get_status(
  --/** Gets the status of the task.
  --    @author Michael Pih
  --    @param case_id			The case_id
  --	@param transition_key		The transition
  --    @return HTML-formatted status of the task, null otherwise
  --*/        
    case_id		in wf_cases.case_id%TYPE,
    transition_key	in wf_transitions.transition_key%TYPE
  ) return varchar2;


  function can_touch (
  --/** Returns 't' if a user has permission to touch an item
  --    @author Michael Pih
  --    @param item_id	The item
  --	@param user_id  The user
  --    @return 't' if a user has permission to touch an item, 'f' otherwise
  --      An item is touchable if:
  --      1) the user has admin privileges on the
  --      2) a workflow exists, current task assigned to user, and
  --          the task is not checked out
  --*/ 
    item_id	in cr_items.item_id%TYPE,
    user_id     in users.user_id%TYPE
  ) return char;



  function unfinished_workflow_exists (
  --/** Returns 't' if an unfinished (not cancelled) workflow exists
  --    otherwise returns 'f'
  --    @author Michael Pih
  --    @param item_id	The item
  --    @return 't' if a workflow case exists and is not in the 'finished' or
  --            'canceled' state
  --*/ 
    item_id	in cr_items.item_id%TYPE
  ) return char;


end content_workflow;
/
show errors





create or replace package body content_workflow 
as

  function is_overdue(
    v_task_id in wf_tasks.task_id%TYPE
  ) return char
  is 
    v_overdue_p char;
  begin
    select 
      't'
    into 
      v_overdue_p
    from
      wf_tasks t, wf_case_deadlines dead
    where
      t.task_id = v_task_id
    and
      t.case_id = dead.case_id
    and
      t.transition_key = dead.transition_key
    and
      t.workflow_key = dead.workflow_key
    and
      dead.deadline is not null
    and
      dead.deadline < trunc(sysdate);

    return v_overdue_p;
    exception
      when NO_DATA_FOUND then 
        return 'f';
  end is_overdue;



  function is_overdue(
    case_id	 in wf_cases.case_id%TYPE,
    transition_key in wf_transitions.transition_key%TYPE
  ) return char
  is 
    v_overdue_p char;
  begin
    select 
      't' into v_overdue_p
    from
      wf_case_deadlines dead
    where
      case_id = is_overdue.case_id
    and
      transition_key = is_overdue.transition_key
    and
      deadline is not null
    and
      deadline < trunc(sysdate)
    and
      content_workflow.is_finished(is_overdue.case_id, 
        is_overdue.transition_key) = 'f';

    return v_overdue_p;
    exception
      when NO_DATA_FOUND then 
        return 'f';
  end is_overdue;



  function get_holding_user_name(
    v_task_id in wf_tasks.task_id%TYPE
  ) return varchar2
  is
    v_name varchar2(100);
  begin

    select
      first_names || ' ' || last_name
    into
      v_name
    from
      persons p, wf_tasks t
    where
      t.holding_user = p.person_id
    and
      t.task_id = v_task_id;

    return v_name;
    exception
      when NO_DATA_FOUND then 
        return null;
  end get_holding_user_name;



  function get_first_place
    return wf_places.place_key%TYPE
  is
    v_first_place wf_places.place_key%TYPE;
  begin

    select
      place_key into v_first_place
    from
      wf_places w
    where
      workflow_key = 'publishing_wf'
    and
      sort_order = (select 
                      min(sort_order) 
		    from 
		      wf_places
		    where
		      workflow_key = w.workflow_key);

    return v_first_place;

    exception when no_data_found then
      return null;
  end get_first_place;



  function get_this_place(
    transition_key	in wf_transitions.transition_key%TYPE
  ) return wf_places.place_key%TYPE
  is
    v_this_place	wf_places.place_key%TYPE;
  begin

    select 
      place_key into v_this_place
    from 
      wf_arcs
    where
      transition_key = get_this_place.transition_key
    and
      workflow_key = 'publishing_wf'
    and
      direction = 'in';

    return v_this_place;
  
    exception
      when no_data_found then
        raise_application_error(-20000, 'Bad transition key ' || 
          get_this_place.transition_key
        );
  end get_this_place;



  function get_next_place(
    transition_key	in wf_transitions.transition_key%TYPE
  ) return wf_places.place_key%TYPE 
  is
    v_next_place  wf_places.place_key%TYPE;

    cursor c_places_cur is
      select 
        there.place_key 
      from
        wf_places here, wf_places there
      where
        here.workflow_key = 'publishing_wf'
      and
        here.workflow_key = there.workflow_key
      and
        here.place_key = content_workflow.get_this_place(
          get_next_place.transition_key )
      and
        there.sort_order > here.sort_order
      order by 
        there.sort_order;
  begin

    open c_places_cur;
    fetch c_places_cur into v_next_place;
    if c_places_cur%NOTFOUND then
      close c_places_cur; 
      raise_application_error (-20000, 
        'content_workflow.get_next_place - No next place - Dead End'
      );
    end if;
    close c_places_cur; 

    return v_next_place;
    exception
      when NO_DATA_FOUND then
        if c_places_cur%ISOPEN then
           close c_places_cur;
        end if;
        return null;
  end get_next_place;



  function get_previous_place(
    transition_key	in wf_transitions.transition_key%TYPE
  ) return wf_places.place_key%TYPE 
  is
    v_previous_place  wf_places.place_key%TYPE;

    cursor c_places_cur is
      select 
        there.place_key 
      from
        wf_places here, wf_places there
      where
        here.workflow_key = 'publishing_wf'
      and
        here.workflow_key = there.workflow_key
      and
        here.place_key = content_workflow.get_this_place(
          get_previous_place.transition_key )
      and
        there.sort_order < here.sort_order
      order by 
        there.sort_order desc;
  begin

    open c_places_cur;
    fetch c_places_cur into v_previous_place;
    if c_places_cur%NOTFOUND then
      close c_places_cur; 
      raise_application_error (-20000, 
        'content_workflow.get_previous_place - No previous place - Dead End'
      );
    end if;
    close c_places_cur; 

    return v_previous_place;
    exception
      when NO_DATA_FOUND then
        if c_places_cur%ISOPEN then
           close c_places_cur;
        end if;
        return null;
  end get_previous_place;



  procedure checkout (
    task_id		in wf_tasks.task_id%TYPE,
    hold_timeout	in wf_tasks.hold_timeout%TYPE,
    user_id		in acs_objects.creation_user%TYPE,
    ip_address		in acs_objects.creation_ip%TYPE,
    msg			in varchar
  )
  is    
    v_task_state	wf_tasks.state%TYPE;
    v_holding_user	wf_tasks.holding_user%TYPE;
    v_journal_id	number;
    v_transition_key	wf_transitions.transition_key%TYPE;
    v_this_place	wf_places.place_key%TYPE;
  begin
    
    -- find out who is holding the task right now
    select
      state, holding_user, transition_key
     into 
       v_task_state, v_holding_user, v_transition_key
    from
      wf_tasks
    where
      task_id = checkout.task_id;

    -- someone else has already holds this task
    -- we need to check in the task as the other person before 
    --    this user can check it out
    if v_task_state = 'started' and v_holding_user is not null 
       and v_holding_user ^= checkout.user_id then

      -- need to manually update the state otherwise a new task is created
      update wf_tasks
        set state = 'enabled',
	holding_user = null,
	hold_timeout = null
        where task_id = checkout.task_id;

      v_task_state := 'enabled';
    end if;

    -- actually check out the item 
    -- (start the task but don't change 'next_place')
    if v_task_state = 'enabled' then

      v_journal_id := workflow_case.begin_task_action(
          task_id    => checkout.task_id,
          action     => 'start',
          action_ip  => checkout.ip_address,
          user_id    => checkout.user_id,
          msg        => checkout.msg
      ); 

      v_this_place := content_workflow.get_this_place( v_transition_key );

      workflow_case.set_attribute_value(
          journal_id     => v_journal_id,
	  attribute_name => 'next_place',
	  value		 => v_transition_key
      );

      workflow_case.end_task_action(
          task_id    => checkout.task_id,
          action     => 'start',
          journal_id => v_journal_id
      );

      -- change the holding user and hold timeout
      update wf_tasks
        set hold_timeout = checkout.hold_timeout,
        holding_user = checkout.user_id
        where task_id = checkout.task_id;

      if v_holding_user is not null and 
        v_holding_user ^= checkout.user_id then

        -- send a notification
        content_workflow.notify_of_checkout(
            task_id          => checkout.task_id,
	    holding_user_old => v_holding_user,
	    holding_user_new => checkout.user_id,
	    msg		     => checkout.msg
        );
      end if;

    else
      raise_application_error(-20000,
        'Cannot check out this task because it''s in an invalid state ' 
	||  v_task_state
      );
    end if;

  end checkout;



  procedure checkin (
    task_id		in wf_tasks.task_id%TYPE,
    user_id		in acs_objects.creation_user%TYPE,
    ip_address		in acs_objects.creation_ip%TYPE,
    msg			in varchar
  ) is
    v_task_state	wf_tasks.state%TYPE;
    v_holding_user	wf_tasks.holding_user%TYPE;  
    v_journal_id	number;
    v_this_place	wf_places.place_key%TYPE;
    v_transition_key	wf_transitions.transition_key%TYPE;
  begin

    -- find out who is holding the task right now
    select
      state, holding_user, transition_key
    into 
      v_task_state, v_holding_user, v_transition_key
    from
      wf_tasks
    where
      task_id = checkin.task_id;

    if v_task_state = 'started' and v_holding_user = checkin.user_id then


      v_journal_id := workflow_case.begin_task_action(
          task_id   => checkin.task_id,
	  action    => 'finish',
	  user_id   => checkin.user_id,
	  action_ip => checkin.ip_address,
	  msg	    => checkin.msg
      );

      v_this_place := content_workflow.get_this_place( v_transition_key );

      workflow_case.set_attribute_value(
          journal_id     => v_journal_id,
	  attribute_name => 'next_place',
	  value		 => v_this_place
      );

      workflow_case.end_task_action(
          journal_id => v_journal_id,
	  action     => 'finish',
	  task_id    => checkin.task_id
      );


    elsif v_task_state ^= 'started' then
      raise_application_error( -20000,
        'Cannot chack in this task because it''s in an invalid state '
         || v_task_state
      );
    else
      raise_application_error( -20000,
        'Cannot check in this task because user_id ' || user_id ||
	' is not the holding user'
      );
    end if;

  end checkin;



  procedure approve(
    task_id		in wf_tasks.task_id%TYPE,
    user_id		in acs_objects.creation_user%TYPE,
    ip_address		in acs_objects.creation_ip%TYPE,
    msg			in varchar
  ) is
    v_task_state	wf_tasks.state%TYPE;
    v_holding_user	wf_tasks.holding_user%TYPE;  
    v_journal_id	number;
    v_transition_key	wf_transitions.transition_key%TYPE;
    v_next_place	wf_places.place_key%TYPE;
  begin

    -- find out who is holding the task right now
    select
      state, holding_user, transition_key
    into 
      v_task_state, v_holding_user, v_transition_key
    from
      wf_tasks
    where
      task_id = approve.task_id;

    if v_task_state = 'started' and v_holding_user ^= approve.user_id then

      raise_application_error( -20000, 
        'content_workflow.approve - Could not approve task because this task
	 is checked out by someone else ' || v_holding_user
      ); 

    elsif v_task_state ^= 'started' and v_task_state ^= 'enabled' then
      raise_application_error( -20000,
        'content_workflow.approve - Could not approve task because this task
         is in an invalid state ' || v_task_state
      );

    -- user is allowed to finish the task
    else

      -- we need to checkout the task first
      if v_task_state = 'enabled' then
        content_workflow.checkout(
	    task_id	 => approve.task_id,	
	    hold_timeout => null,
	    user_id	 => approve.user_id,
	    ip_address	 => approve.ip_address,
	    msg		 => approve.msg
        );
      end if;

      v_journal_id := workflow_case.begin_task_action(
          task_id    => approve.task_id,
          action     => 'finish',
          action_ip  => approve.ip_address,
          user_id    => approve.user_id,
          msg        => approve.msg
      ); 

      v_next_place := content_workflow.get_next_place(
          transition_key => v_transition_key
      );

      workflow_case.set_attribute_value(
          journal_id     => v_journal_id,
	  attribute_name => 'next_place',
	  value          => v_next_place
      );

      workflow_case.end_task_action(
          task_id    => approve.task_id,
          action     => 'finish',
          journal_id => v_journal_id
      );

    end if;
  end approve;


  procedure reject(
    task_id		in wf_tasks.task_id%TYPE,
    user_id		in acs_objects.creation_user%TYPE,
    ip_address		in acs_objects.creation_ip%TYPE,
    transition_key	in wf_transitions.transition_key%TYPE,
    msg			in varchar
  ) is
    v_task_state	wf_tasks.state%TYPE;
    v_holding_user	wf_tasks.holding_user%TYPE;  
    v_transition_key	wf_transitions.transition_key%TYPE;
    v_journal_id	number;
    v_sanity_check	integer;
    v_previous_place	wf_places.place_key%TYPE;
  begin

    -- find out who is holding the task right now
    select
      state, holding_user, transition_key
    into 
      v_task_state, v_holding_user, v_transition_key
    from
      wf_tasks
    where
      task_id = reject.task_id;

    -- do a quick sanity check
    -- make sure the desired transition is accessible from this transition
    select 
      count(1) into v_sanity_check
    from 
      wf_arcs out, wf_arcs dest
    where 
      out.workflow_key = 'publishing_wf'
   and
      out.workflow_key = dest.workflow_key
    and
      out.direction = 'out' 
    and 
      dest.direction = 'in'
    and
      out.transition_key = v_transition_key
    and
      dest.transition_key = reject.transition_key
    and
      reject.transition_key ^= v_transition_key
    and
      -- make sure the arcs are connected
      out.place_key = dest.place_key;


    if v_sanity_check = 0 then
      raise_application_error( -20000,
        'content_workflow.reject - Sanity check failed - invalid transition: '
	|| reject.transition_key
      );
    end if;


    if v_task_state = 'started' and v_holding_user ^= reject.user_id then
      raise_application_error( -20000, 
        'content_workflow.reject - Could not reject task because this task
	 is checked out by someone else ' || v_holding_user
      ); 
    elsif v_task_state ^= 'started' and v_task_state ^= 'enabled' then
      raise_application_error( -20000,
        'content_workflow.approve - Could not reject task because this task
         is in an invalid state ' || v_task_state
      );
    else

      -- we need to start this task first
      if v_task_state = 'enabled' then
        content_workflow.checkout(
	    task_id	 => reject.task_id,	
	    hold_timeout => null,
	    user_id	 => reject.user_id,
	    ip_address	 => reject.ip_address,
	    msg		 => reject.msg
        );

      end if;


      -- ok to reject this task
      v_journal_id := workflow_case.begin_task_action(
          task_id    => reject.task_id,
          action     => 'finish',
          action_ip  => reject.ip_address,
          user_id    => reject.user_id,
          msg        => reject.msg
      ); 

      v_previous_place := content_workflow.get_this_place(
          transition_key => reject.transition_key
      );

      workflow_case.set_attribute_value(
          journal_id     => v_journal_id,
	  attribute_name => 'next_place',
	  value          => v_previous_place
      );

      workflow_case.end_task_action(
          task_id    => reject.task_id,
          action     => 'finish',
          journal_id => v_journal_id
      );

    end if;
  end reject;





  procedure notify_of_checkout (
    task_id			in wf_tasks.task_id%TYPE,
    holding_user_old		in wf_tasks.holding_user%TYPE,
    holding_user_new		in wf_tasks.holding_user%TYPE,
    msg				in varchar
  ) is
    v_hold_user_old	varchar(100);
    v_hold_user_new	varchar(100);
    v_transition_name	wf_transitions.transition_name%TYPE;
    v_request_id	acs_mail_queue_messages.message_id%TYPE;
    v_item_name		varchar(100);
  begin

    -- get the robbed users name
    select
      first_names || ' ' || last_name into v_hold_user_old
    from
      persons
    where
      person_id = notify_of_checkout.holding_user_old;

    -- get the lock stealers name
    select
      first_names || ' ' || last_name into v_hold_user_new
    from
      persons
    where
      person_id = notify_of_checkout.holding_user_new;

    -- get the item name and transition name
    select
      transition_name, content_item.get_title( c.object_id )
    into
      v_transition_name, v_item_name
    from
      wf_transitions trans, wf_tasks t, wf_cases c
    where
      trans.transition_key = t.transition_key
    and
      t.case_id = c.case_id
    and
      t.task_id = notify_of_checkout.task_id;

    -- send out the request
    v_request_id := acs_mail_nt.post_request (
        party_from   => notify_of_checkout.holding_user_new,
        party_to     => notify_of_checkout.holding_user_old,
        expand_group => 'f',
        subject      => v_hold_user_new || ' stole the lock for ' ||
		        v_transition_name || ' of ' || v_item_name,
        message      => 'Dear ' || v_hold_user_old || ',\n' ||
                         notify_of_checkout.msg
    );

  end notify_of_checkout;


  function can_reject(
    task_id	in wf_tasks.task_id%TYPE,
    user_id     in wf_tasks.holding_user%TYPE
  ) return char
  is
    v_transition_key	wf_transitions.transition_key%TYPE;
    v_can_reject	char(1);
  begin

    select
      't' into v_can_reject
    from
      wf_tasks
    where
      task_id = can_reject.task_id
    and
      workflow_key = 'publishing_wf'
    and
      (state = 'enabled'
       or (state = 'started'
           and holding_user = can_reject.user_id))
    and
      content_workflow.get_this_place(transition_key) ^=
       content_workflow.get_first_place;

    return v_can_reject;
    exception
      when NO_DATA_FOUND then
        return 'f';
  end can_reject;



  function can_approve(
    task_id	in wf_tasks.task_id%TYPE,
    user_id	in wf_tasks.holding_user%TYPE
  ) return char
  is
    v_can_approve char(1);
  begin

    select
      't' into v_can_approve
    from
      wf_tasks
    where
      (state = 'enabled' 
       or (state = 'started'
           and holding_user = can_approve.user_id))
    and
      task_id = can_approve.task_id
    and
      workflow_key = 'publishing_wf';

    return v_can_approve;
    exception
      when NO_DATA_FOUND then
        return 'f';

  end can_approve;


 function can_start(
    task_id	in wf_tasks.task_id%TYPE,
    user_id	in wf_tasks.holding_user%TYPE
  ) return char
  is
    v_can_start char(1);
  begin

    select
      't' into v_can_start
    from
      wf_tasks
    where
      (state = 'enabled' 
       or (state = 'started'
           and holding_user ^= can_start.user_id))
    and
      task_id = can_start.task_id
    and
      workflow_key = 'publishing_wf';

    return v_can_start;
    exception
      when NO_DATA_FOUND then
        return 'f';

  end can_start;



  function approve_string(
    task_id	in wf_tasks.task_id%TYPE,
    user_id	in wf_tasks.holding_user%TYPE
  ) return varchar2
  is
    v_transition_key	wf_transitions.transition_key%TYPE;
    v_approve_string	varchar(10);
  begin

    if content_workflow.can_approve( 
      approve_string.task_id, approve_string.user_id ) = 't' then
      
      select
        transition_key into v_transition_key
      from
        wf_tasks
      where
        task_id = approve_string.task_id;

      if content_workflow.get_this_place( v_transition_key ) = 
        content_workflow.get_first_place then
	v_approve_string := 'Finish';
      else
        v_approve_string := 'Approve';
      end if;
      
    else
      v_approve_string := null;
    end if;

    return v_approve_string;
    exception
      when NO_DATA_FOUND then
        return null;

  end approve_string;


  function count_finished_tasks(
    case_id		in wf_cases.case_id%TYPE
  ) return integer
  is
    v_already_finished_tasks	integer;
  begin

    select
      count(before.place_key) into v_already_finished_tasks
    from
      ( 
        select
          p.sort_order
        from
          wf_tasks t, wf_places p
        where
          t.workflow_key = 'publishing_wf'
        and
          t.workflow_key = p.workflow_key
        and
          p.place_key = content_workflow.get_this_place( t.transition_key )
        and
	  -- active task
          t.state in ('enabled', 'started')
        and
          t.case_id = count_finished_tasks.case_id
      ) here,
      wf_places before
    where
      before.workflow_key = 'publishing_wf'
    and
      -- earlier transitions (tasks that have already been completed)
      before.sort_order < here.sort_order;

    return v_already_finished_tasks;
    exception
      when NO_DATA_FOUND then
        return 0;
  end count_finished_tasks;



  function count_unfinished_tasks(
    case_id		in wf_cases.case_id%TYPE
  ) return integer
  is
    v_unfinished_tasks		integer;
    v_already_finished_tasks	integer;
    v_all_tasks			integer;
  begin

    select
      count(transition_key) into v_all_tasks
    from
      wf_transitions
    where
      workflow_key = 'publishing_wf';

    v_already_finished_tasks := content_workflow.count_finished_tasks(
        case_id => count_unfinished_tasks.case_id
    );

    v_unfinished_tasks := v_all_tasks - v_already_finished_tasks;


    return v_unfinished_tasks;
    exception
      when NO_DATA_FOUND then
        return 0;
  end count_unfinished_tasks;


  function is_active (
    case_id	       in wf_cases.case_id%TYPE,
    transition_key     in wf_transitions.transition_key%TYPE
  ) return char
  is
    v_unfinished_count	integer;
  begin

    select 
      count(task_id) into v_unfinished_count
    from
      wf_tasks
    where
      transition_key = is_active.transition_key
    and
      case_id = is_active.case_id
    and
      state in ('started','enabled');

    if v_unfinished_count > 0 then
      return 't';
    else
      return 'f';
    end if;
  end is_active;


  function is_finished (
    case_id	       in wf_cases.case_id%TYPE,
    transition_key     in wf_transitions.transition_key%TYPE
  ) return char
  is

    cursor c_already_finished_tasks is
      select
        trans.transition_key
      from
        wf_transitions trans, wf_places here, wf_places there, wf_tasks t
      where
        trans.workflow_key = 'publishing_wf'
      and
        here.workflow_key = there.workflow_key
      and
        here.workflow_key = trans.workflow_key
      and
        -- the task belongs to this case
        t.case_id = is_finished.case_id
      and
        -- the task is active
        t.state in ('enabled','started')
      and
        -- here is the place the case is currently at
        here.place_key = content_workflow.get_this_place(t.transition_key)
      and
        -- there is the place we're checking if it's finished
        there.place_key = content_workflow.get_this_place(
          trans.transition_key)
      and
        -- there needs to be done before here 
	-- (sort order determines task order)
        there.sort_order < here.sort_order;

  begin

    for v_finished_task in c_already_finished_tasks loop
    
      -- check if this task has already been finished
      if is_finished.transition_key = v_finished_task.transition_key then
        return 't';
      end if;
    end loop;

    return 'f';
  end is_finished;


  function is_checked_out (
    case_id	       in wf_cases.case_id%TYPE,
    transition_key     in wf_transitions.transition_key%TYPE
  ) return char
  is
    v_checkout_count	integer;
  begin
    select
      count(*) into v_checkout_count
    from
      wf_tasks t
    where
      workflow_key = 'publishing_wf'
    and
      case_id = is_checked_out.case_id
    and
      transition_key = is_checked_out.transition_key
    and
      state = 'started';

    if v_checkout_count > 0 then
      return 't';
    else
      return 'f';
    end if;

  end is_checked_out;


  function is_checked_out (
    case_id	       in wf_cases.case_id%TYPE,
    transition_key     in wf_transitions.transition_key%TYPE,
    user_id	       in wf_tasks.holding_user%TYPE
  ) return char
  is
    v_checkout_count	integer;
  begin
    select
      count(task_id) into v_checkout_count
    from
      wf_tasks t
    where
      workflow_key = 'publishing_wf'
    and
      case_id = is_checked_out.case_id
    and
      transition_key = is_checked_out.transition_key
    and
      state = 'started'
    and
      holding_user = is_checked_out.user_id;

    if v_checkout_count > 0 then
      return 't';
    else
      return 'f';
    end if;

  end is_checked_out;


  function get_status(
    case_id		in wf_cases.case_id%TYPE,
    transition_key	in wf_transitions.transition_key%TYPE
  ) return varchar2
  is
    v_status		varchar(1000);
    v_state		wf_tasks.state%TYPE;
    v_holding_user	wf_tasks.holding_user%TYPE;
    v_hold_timeout	wf_tasks.hold_timeout%TYPE;
    v_enabled_date	wf_tasks.enabled_date%TYPE;
    v_started_date	wf_tasks.started_date%TYPE;
  begin

    select
      state, holding_user, hold_timeout, enabled_date, started_date
    into
      v_state, v_holding_user, v_hold_timeout, v_enabled_date, v_started_date
    from
      wf_tasks
    where
      transition_key = get_status.transition_key
    and
      case_id = get_status.case_id
    and
      state in ('enabled','started');

    v_status := '<table><tr><td>Activated on ' || 
      to_char(v_enabled_date,'Mon. DD, YYYY HH24:MI:SS') || 
      '</td></tr>';

    if v_state = 'started' then

      v_status := v_status || 
        '<tr><td><b>Checked Out</b> by <a href="user-tasks.acs?party_id=' ||
	v_holding_user || '">' || person.name(v_holding_user) ||
	'</a> on ' || to_char(v_started_date,'Mon. DD, YYYY HH24:MI:SS') || 
	' until ' ||
	to_char(v_hold_timeout,'Mon. DD, YYYY') || '</td></tr>';
    end if;

    v_status := v_status || '</table>';    

    return v_status;
    exception
      when NO_DATA_FOUND then
        return null;

  end get_status;


  function can_touch (
    item_id	in cr_items.item_id%TYPE,
    user_id     in users.user_id%TYPE
  ) return char
  is
    v_workflow_count integer;
    v_task_count     integer;
  begin

    -- cm_admin has highest precedence
    if content_permission.permission_p( 
      can_touch.item_id, can_touch.user_id, 'cm_item_workflow' ) = 't' then
      return 't';
    end if;

    select
      count(case_id) into v_workflow_count
    from
      wf_cases
    where
      object_id = can_touch.item_id;

    -- workflow must exist
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
      c.object_id = can_touch.item_id
    and
      ( t.state = 'enabled' 
        or 
          ( t.state = 'started' and t.holding_user = can_touch.user_id ))
    and
      t.user_id = can_touch.user_id;


    -- is the user assigned a current task on this item
    if v_task_count = 0 then
      return 'f';
    else
      return 't';
    end if;

  end can_touch;



  function unfinished_workflow_exists (
    item_id	in cr_items.item_id%TYPE
  ) return char
  is
    v_wf_count integer;
  begin

    select 
      count(*) into v_wf_count
    from
      wf_cases
    where
      object_id = unfinished_workflow_exists.item_id
    and
      workflow_key = 'publishing_wf'
    and
      state in ('active', 'created', 'suspended');
    
    if v_wf_count > 0 then
      return 't';
    else
      return 'f';
    end if;

  end unfinished_workflow_exists;

end content_workflow;
/
show errors


