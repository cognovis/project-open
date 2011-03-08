alter session set sql_trace = false
set autotrace off
set timing off

create or replace function
my_random
return integer
is
begin
    return dbms_random.random/power(2,32)+0.5;
end my_random;
/
show errors

create or replace procedure
push_task_ahead(
    task_id integer,
    state in varchar2,
    user_id in integer,
    workflow_key in varchar2,
    transition_key in varchar2
)
is
   v_journal_id integer;
   v_value char(1);
begin
    if state = 'enabled' then
        v_journal_id := workflow_case.task_action(
	    task_id => push_task_ahead.task_id, 
	    action => 'start',
	    action_ip => '1.1.1.1',
	    user_id => push_task_ahead.user_id
        );
    else
        /* State must be started */
        if my_random < 0.02 then
	    v_journal_id := workflow_case.task_action(
	        task_id => push_task_ahead.task_id,
	  	action => 'cancel',
		action_ip => '1.1.1.1',
		user_id => push_task_ahead.user_id
	    );
        else
	    v_journal_id := workflow_case.begin_task_action(
	        task_id => push_task_ahead.task_id,
	  	action => 'finish',
		action_ip => '1.1.1.1',
		user_id => push_task_ahead.user_id
	    );

            for attr_rec in (select a.attribute_name, datatype
		 	       from wf_transition_attribute_map m, acs_attributes a
			      where workflow_key = push_task_ahead.workflow_key
			        and transition_key = push_task_ahead.transition_key
				and a.attribute_id = m.attribute_id)
            loop
		/* We only know how to handle boolean attributes ... but that's the only thing we have right now, so ... */
	 	if attr_rec.datatype = 'boolean' then
		    if my_random < 0.5 then
			v_value := 't';
		    else
		        v_value := 'f';
		    end if;

		    workflow_case.set_attribute_value(
			journal_id => v_journal_id,	
			attribute_name => attr_rec.attribute_name,
			value => v_value
		    );
 		end if;
            end loop;

	    workflow_case.end_task_action(
	   	journal_id => v_journal_id,
	  	action => 'finish',
	        task_id => push_task_ahead.task_id
	    );
        end if;
    end if;
end;
/
show errors


declare
  v_object_id integer;
  v_workflow_key varchar2(100);
  v_count integer;
  v_num_cases integer;
  v_party_id integer;
  v_case_id integer;
  v_task_id integer;
  v_user_id integer;
  v_num_tasks integer;
  v_state varchar2(100);
  v_transition_key varchar2(100);
begin
    v_num_cases := 100;
    dbms_random.initialize(943820482);

    /* Create a shit-load of cases */

    for v_count in 1 .. v_num_cases
    loop
		
        select object_id into v_object_id from acs_objects where rownum = 1;
	
	select workflow_key into v_workflow_key from wf_workflows where rownum = 1;
        
	v_case_id := workflow_case.new(
	    workflow_key => v_workflow_key,
	    object_id => v_object_id
        );

        for trans_rec in (select transition_key from wf_transitions where workflow_key = v_workflow_key) loop
            for party_rec in (select party_id from parties sample(50)) loop
		workflow_case.add_manual_assignment(
		    case_id => v_case_id,
		    transition_key => trans_rec.transition_key,	
		    party_id => party_rec.party_id
		);
     	    end loop;
	end loop;

        workflow_case.start_case(
	    case_id => v_case_id
        );       

    end loop;

    /* Move 85% of the cases all the way to finished */

    for case_rec in (select case_id from wf_cases sample (85))
    loop
	loop
	    select decode(count(*), 0, 0, 1) into v_num_tasks from wf_user_tasks;
	    exit when v_num_tasks = 0;

	    if my_random < 0.005 then
		workflow_case.cancel(
	            case_id => case_rec.case_id
		);
	    end if;

            select task_id, state, user_id, workflow_key, transition_key
	      into v_task_id, v_state, v_user_id, v_workflow_key, v_transition_key
	      from wf_user_tasks
	     where case_id = case_rec.case_id
	       and rownum = 1;

	    push_task_ahead(
		task_id => v_task_id,
		state => v_state,
		user_id => v_user_id,
		workflow_key => v_workflow_key,
		transition_key => v_transition_key
	    );	    
        end loop;
    end loop;


    /* Fire transitions at random */

    for v_count in 1 .. round(v_num_cases * 0.15 * 3)
    loop
        select decode(count(*), 0, 0, 1) into v_num_tasks from wf_user_tasks;
        exit when v_num_tasks = 0;

        select task_id, state, user_id, workflow_key, transition_key
          into v_task_id, v_state, v_user_id, v_workflow_key, v_transition_key
          from wf_user_tasks
         where rownum = 1;

        push_task_ahead(
            task_id => v_task_id,
            state => v_state,
            user_id => v_user_id,
            workflow_key => v_workflow_key,
            transition_key => v_transition_key
        );	    
    end loop;
end;
/
show errors


