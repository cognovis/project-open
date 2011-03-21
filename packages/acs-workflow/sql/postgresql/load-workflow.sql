
create function my_random()
returns integer '
begin
    return random();
end;' language 'plpgsql';



-- show errors

create function push_task_ahead(integer,varchar,integer,varchar,varchar)
returns integer as '
declare
    push_task_ahead__task_id             alias for $1;
    push_task_ahead__state               alias for $2;
    push_task_ahead__user_id             alias for $3;
    push_task_ahead__workflow_key        alias for $4;
    push_task_ahead__transition_key      alias for $5;
    v_journal_id                         integer;
    v_value                              char(1);
    attr_rec                             record;
begin
    if state = ''enabled'' then
        v_journal_id := workflow_case__task_action (
	    push_task_ahead__task_id,
	    ''start'',
	    ''1.1.1.1'',
	    push_task_ahead__user_id,
	    null
	    );
    else
        /* State must be started */
        if my_random() < 0.02 then
	    v_journal_id := workflow_case__task_action (
		push_task_ahead__task_id,
		''cancel'',
		''1.1.1.1'',
		push_task_ahead__user_id,
		null
		);
        else
	    v_journal_id := workflow_case__begin_task_action (
		push_task_ahead__task_id,
		''finish'',
		''1.1.1.1'',
		push_task_ahead__user_id,
		null
		);

            for attr_rec in select a.attribute_name, datatype
		 	       from wf_transition_attribute_map m, acs_attributes a
			      where workflow_key = push_task_ahead.workflow_key
			        and transition_key = push_task_ahead.transition_key
				and a.attribute_id = m.attribute_id
            loop
		/* We only know how to handle boolean attributes ... 
                but that''s the only thing we have right now, so ... */

	 	if attr_rec.datatype = ''boolean'' then
		    if my_random() < 0.5 then
			v_value := ''t'';
		    else
		        v_value := ''f'';
		    end if;

		    select workflow_case__set_attribute_value (
			v_journal_id,
			attr_rec.attribute_name,
			v_value
			);
 		end if;
            end loop;

	    select workflow_case__end_task_action (
	        v_journal_id,
	        ''finish'',
	        push_task_ahead__task_id
	        );
        end if;
    end if;

    return 0;
end;' language 'plpgsql';

select inline_1 ();

drop function inline_1 ();


-- show errors


create function inline_2 ()
returns integer as '
declare
  v_object_id           integer;
  v_workflow_key        varchar(100);
  v_count               integer;
  v_num_cases           integer;
  v_party_id            integer;
  v_case_id             integer;
  v_task_id             integer;
  v_user_id             integer;
  v_num_tasks           integer;
  v_state               varchar(100);
  v_transition_key      varchar(100);
  trans_rec             record;
  party_rec             record;
  case_rec              record;
begin
    v_num_cases := 100;

    --select dbms_random__initialize (943820482);
    --	    );

        for trans_rec in select transition_key 
                         from wf_transitions 
                         where workflow_key = v_workflow_key
        LOOP
            for party_rec in select party_id 
                             from parties sample(50) 
            LOOP
		select workflow_case__add_manual_assignment (
		    v_case_id,
		    trans_rec.transition_key,
		    party_rec.party_id
		    );
     	    end loop;
	end loop;

        select workflow_case__start_case (
	    v_case_id,
	    null,
	    null,
	    null
	    );

    end loop;

    /* Move 85% of the cases all the way to finished */

    for case_rec in select case_id from wf_cases sample (85)
    loop
	loop
	    select case when count(*) = 0 then 0 else 1 end into v_num_tasks 
            from wf_user_tasks;

	    exit when v_num_tasks = 0;

	    if my_random() < 0.005 then
		select workflow_case__cancel (
	            case_rec.case_id,
	            null,
	            null,
	            null
	            );
	    end if;

            select task_id, state, user_id, workflow_key, transition_key
	      into v_task_id, v_state, v_user_id, v_workflow_key, v_transition_key
	      from wf_user_tasks
	     where case_id = case_rec.case_id
	       and rownum = 1;

	    PERFORM push_task_ahead(
		v_task_id,
		v_state,
		v_user_id,
		v_workflow_key,
		v_transition_key
	    );	    
        end loop;
    end loop;


    /* Fire transitions at random */

    for v_count in 1 .. round(v_num_cases * 0.15 * 3)
    loop
        select case when count(*) = 0 then 0 else 1 end into v_num_tasks 
        from wf_user_tasks;

        exit when v_num_tasks = 0;

        select task_id, state, user_id, workflow_key, transition_key
          into v_task_id, v_state, v_user_id, v_workflow_key, v_transition_key
          from wf_user_tasks
         limit 1;

        PERFORM push_task_ahead(
            v_task_id,
            v_state,
            v_user_id,
            v_workflow_key,
            v_transition_key
        );	    
    end loop;

    return 0;
end;' language 'plpgsql';

select inline_2 ();

drop function inline_2 ();


-- show errors


