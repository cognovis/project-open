-- set serveroutput on size 1000000 format wrapped

-- requires the utPLSQL system
-- 
-- modify this line to suit your needs
-- 
-- exec utplsql.setdir('/web/lars-dev2/packages/acs-kernel/sql');

-- exec utplsql.autocompile (false);

-- create or replace package ut#workflow_case
-- as
-- 
--     procedure setup;
-- 
--     procedure teardown;
-- 
--     procedure run;
-- 
-- end ut#workflow_case;
-- /
-- show errors

-- create or replace package body ut#workflow_case

create function utassert__eq(varchar,integer,integer) returns integer as '
declare
        v_msg   alias for $1;
        v_in    alias for $2;
        v_chk   alias for $3;
begin
        if v_in != v_chk then 
           raise NOTICE ''%: failed'', v_msg;
        end if;

        return null;

end;' language 'plpgsql';
create function utassert__eq(varchar,text,text) returns integer as '
declare
        v_msg   alias for $1;
        v_in    alias for $2;
        v_chk   alias for $3;
begin
        if v_in != v_chk then 
           raise NOTICE ''%: failed'', v_msg;
        end if;

        return null;

end;' language 'plpgsql';

create function setup() returns integer as '
declare
	wf_count integer;
        exists_p boolean;
begin
	PERFORM teardown();
        raise NOTICE ''Setting up...'';

	/* We assume that the sample-expenses workflow is loaded and 
        unchanged from the original */

        select count(*) > 0 into exists_p 
        from pg_proc 
        where proname = ''acs_mail_nt__post_request'';

        if NOT exists_p then
           execute ''create function acs_mail_nt__post_request(integer,integer,boolean,text,text,integer) returns integer as \\\'
begin
        return null;
end;\\\' language \\\'plpgsql\\\''';
        end if;

	select case when count(*) = 0 then 0 else 1 end  
        into wf_count 
        from wf_workflows 
        where workflow_key = ''expenses_wf'';

	if wf_count = 0 then
	    raise EXCEPTION ''-20000: The sample-expenses workflow must be loaded (and unchanged from the original)'';
	end if;

        return null;

end;' language 'plpgsql';

create function teardown() returns integer as '
begin
        raise NOTICE ''Tearing down...'';

        return null;
	
end;' language 'plpgsql';

create function run() returns integer as '
declare
	v_workflow_key  wf_workflows.workflow_key%TYPE;
	v_object_id     acs_objects.object_id%TYPE;
	v_case_id       wf_cases.case_id%TYPE;
	v_count         integer;
	v_task_id       integer;
	v_journal_id    integer;
	v_user_id       integer;
	v_state         varchar(100);
begin
	v_workflow_key := ''expenses_wf'';
        PERFORM acs_user__new(
                null,
                ''user'',
                now(),
                null,
                ''127.0.0.1'',                
                ''jane.doe@arsdigita.com'',
                null,
                ''Jane'',
                ''Doe'',
                ''janedoerules'',
                null,
                null,
                null,
                null,
                ''t'',
                null
                );
	
        raise NOTICE ''Running test...'';

	/* Pick out a random object ... we just hope there is one somewhere */
	select object_id into v_object_id 
        from acs_objects
        limit 1;
	
        raise NOTICE ''. new case'';

	v_case_id := workflow_case__new(
            null,
            v_workflow_key,
            ''default'',
            v_object_id,
            now(),
            null,
            null
        );
	
	raise NOTICE ''. manual assignments'';

	/* we need a random user_id */
	select user_id into v_user_id
	from   users
	limit 1;

	PERFORM workflow_case__add_manual_assignment (
	    v_case_id,
	    ''assign'',
	    v_user_id
	);

	PERFORM workflow_case__add_manual_assignment (
	    v_case_id,
	    ''supervisor_approval'',
	    v_user_id
	);

	PERFORM workflow_case__add_manual_assignment (
	    v_case_id,
	    ''other_approval'',
	    v_user_id
	);

	PERFORM workflow_case__add_manual_assignment (
	    v_case_id,
	    ''buy'',
	    v_user_id
	);



	raise NOTICE ''. start case'';

	PERFORM workflow_case__start_case(
	    v_case_id,
            null,
            null,
            null
        );
	
	select count(*) into v_count 
	from   wf_tasks 
	where  case_id = v_case_id
	and    transition_key = ''assign''
	and    state = ''enabled'';

	PERFORM utassert__eq(
	    ''We should have exactly one "assign" task enabled'',
	    1, 
            v_count
        );

	select count(*) into v_count 
	from   wf_tasks 
	where  case_id = v_case_id;

	PERFORM utassert__eq(
	    ''The "assign" task should be the only task there is for this case yet.'',
	    1,
	    v_count
        );

	/* Get that task_id */
	select task_id into v_task_id
	from wf_tasks
	where case_id = v_case_id
	and   transition_key = ''assign''
	and   state = ''enabled'';




	raise NOTICE ''. start task "assign"'';

	v_journal_id := workflow_case__begin_task_action(
	    v_task_id,
	    ''start'',
	    ''0.0.0.0'',
	    v_user_id,
	    ''regression-test: started task "assign"''
	);

	PERFORM workflow_case__end_task_action(
	    v_journal_id,
	    ''start'',
	    v_task_id
        );

	select state into v_state
	from   wf_tasks
	where  task_id = v_task_id;
	
	PERFORM utassert__eq(
	    ''The "assign" task should be in state "started".'',
	    ''started'',
	    v_state
        );

	raise NOTICE ''. cancel task "assign"'';

	v_journal_id := workflow_case__begin_task_action(
	    v_task_id,
	    ''cancel'',
	    ''0.0.0.0'',
	    v_user_id,
	    ''regression-test: canceled task "assign"''
	);

	PERFORM workflow_case__end_task_action(
	    v_journal_id,
	    ''cancel'',
	    v_task_id
        );

	select state into v_state
	from   wf_tasks
	where  task_id = v_task_id;
	
	PERFORM utassert__eq(
	    ''The "assign" task should be in state "canceled".'',
	    ''canceled'',
	    v_state
        );


	select count(*) into v_count 
	from   wf_tasks 
	where  case_id = v_case_id
	and    transition_key = ''assign''
	and    state = ''enabled'';

	PERFORM utassert__eq(
	    ''We should have exactly one "assign" task enabled'',
	    1,
            v_count
        );

	select count(*) into v_count 
	from   wf_tasks 
	where  case_id = v_case_id;

	PERFORM utassert__eq(
	    ''There should be exactly two tasks for this case, one enabled and one canceled.'',
	    2,
	    v_count
        );


	raise NOTICE ''. finish task "assign"'';

	/* Get that task_id for the assign task */
	select task_id into v_task_id
	from wf_tasks
	where case_id = v_case_id
	and   transition_key = ''assign''
	and   state = ''enabled'';
	
	v_journal_id := workflow_case__begin_task_action(
	    v_task_id,
	    ''finish'',
	    ''0.0.0.0'',
	    v_user_id,
	    ''regression-test: finished task "assign"''
	);

	PERFORM workflow_case__end_task_action(
	    v_journal_id,
	    ''finish'',
	    v_task_id
        );
	
	select state into v_state
	from   wf_tasks
	where  task_id = v_task_id;

	PERFORM utassert__eq(
	    ''The "assign" task should be in state "finished".'',
	    ''finished'',
	    v_state
        );

	select count(*) into v_count 
	from   wf_tasks 
	where  case_id = v_case_id
	and    transition_key = ''supervisor_approval''
	and    state = ''enabled'';

	PERFORM utassert__eq(
	    ''We should have exactly one "supervisor_approval" task enabled'',
	    1,
            v_count
        );

	select count(*) into v_count 
	from   wf_tasks 
	where  case_id = v_case_id
	and    transition_key = ''other_approval''
	and    state = ''enabled'';

	PERFORM utassert__eq(
	    ''We should have exactly one "other_approval" task enabled'',
	    1,
            v_count
        );

	select count(*) into v_count 
	from   wf_tasks 
	where  case_id = v_case_id;

	PERFORM utassert__eq(
	    ''There should be exactly five tasks for this case, one canceled, two finished, and two enabled.'',
	    5,
	    v_count
        );

	
	raise NOTICE ''. finish task "supervisor_approval" without starting it first (saying okay)'';

	/* Get the task_id for the supervisor_approval task */
	select task_id into v_task_id
	from wf_tasks
	where case_id = v_case_id
	and   transition_key = ''supervisor_approval''
	and   state = ''enabled'';

	v_journal_id := workflow_case__begin_task_action(
	    v_task_id,
	    ''finish'',
	    ''0.0.0.0'',
	    v_user_id,
	    ''regression-test: finished task "supervisor_approval"''
	);

	PERFORM workflow_case__set_attribute_value(
	    v_journal_id,
	    ''supervisor_ok'',
	    ''t''
        );

	PERFORM workflow_case__end_task_action(
	    v_journal_id,
	    ''finish'',
	    v_task_id
        );
	
	select state into v_state
	from   wf_tasks
	where  task_id = v_task_id;

	PERFORM utassert__eq(
	    ''The "supervisor_approval" task should be in state "finished".'',
	    ''finished'',
	    v_state
        );
	


	raise NOTICE ''. finish task "other_approval" without starting it first (saying okay)'';

	/* Get the task_id for the other_approval task */
	select task_id into v_task_id
	from wf_tasks
	where case_id = v_case_id
	and   transition_key = ''other_approval''
	and   state = ''enabled'';

	v_journal_id := workflow_case__begin_task_action(
	    v_task_id,
	    ''finish'',
	    ''0.0.0.0'',
	    v_user_id,
	    ''regression-test: finished task "other_approval"''
	);

	PERFORM workflow_case__set_attribute_value(
	    v_journal_id,
	    ''other_ok'',
	    ''t''
        );
	PERFORM workflow_case__end_task_action(
	    v_journal_id,
	    ''finish'',
	    v_task_id
        );
	
	select state into v_state
	from   wf_tasks
	where  task_id = v_task_id;

	PERFORM utassert__eq(
	    ''The "other_approval" task should be in state "finished".'',
	    ''finished'',
	    v_state
        );
	
	select count(*) into v_count 
	from   wf_tasks 
	where  case_id = v_case_id
	and    state = ''enabled'';

	PERFORM utassert__eq(
	    ''We should have exactly one task enabled'',
	    1,
            v_count
        );

	select count(*) into v_count 
	from   wf_tasks 
	where  case_id = v_case_id
	and    transition_key = ''buy''
	and    state = ''enabled'';

	PERFORM utassert__eq(
	    ''We should have the "buy" task enabled'',
	    1,
            v_count
        );

	select count(*) into v_count 
	from   wf_tasks 
	where  case_id = v_case_id;

	PERFORM utassert__eq(
	    ''There should be exactly seven tasks for this case, one canceled, six finished, and one enabled.'',
	    7,
	    v_count
        );

	select count(*) into v_count 
	from   wf_tasks 
	where  case_id = v_case_id
	and    state = ''finished'';

	PERFORM utassert__eq(
	    ''There should be exactly five finished tasks'',
	    5,
	    v_count
        );

	select count(*) into v_count 
	from   wf_tasks 
	where  case_id = v_case_id
	and    state = ''canceled'';

	PERFORM utassert__eq(
	    ''There should be exactly one canceled task'',
	    1,
	    v_count
        );
	

	raise NOTICE ''. finish task "buy"'';

	/* Get that task_id for the ''buy'' task */
	select task_id into v_task_id
	from wf_tasks
	where case_id = v_case_id
	and   transition_key = ''buy''
	and   state = ''enabled'';
	
	v_journal_id := workflow_case__begin_task_action(
	    v_task_id,
	    ''finish'',
	    ''0.0.0.0'',
	    v_user_id,
	    ''regression-test: finished task "buy"''
	);

	PERFORM workflow_case__end_task_action(
	    v_journal_id,
	    ''finish'',
	    v_task_id
        );
	
	select state into v_state
	from   wf_tasks
	where  task_id = v_task_id;

	PERFORM utassert__eq(
	    ''The "buy" task should be in state "finished".'',
	    ''finished'',
	    v_state
        );

	select count(*) into v_count 
	from   wf_tasks 
	where  case_id = v_case_id;

	PERFORM utassert__eq(
	    ''There should be exactly seven tasks for this case, one canceled, six finished, and one enabled.'',
	    7,
	    v_count
        );

	select count(*) into v_count 
	from   wf_tasks 
	where  case_id = v_case_id
	and    state = ''finished'';

	PERFORM utassert__eq(
	    ''There should be exactly six finished tasks'',
	    6,
	    v_count
        );

	select count(*) into v_count 
	from   wf_tasks 
	where  case_id = v_case_id
	and    state = ''canceled'';

	PERFORM utassert__eq(
	    ''There should be exactly one canceled task'',
	    1,
	    v_count
        );
	
	select state into v_state
	from   wf_cases
	where  case_id = v_case_id;

	PERFORM utassert__eq(
	    ''The case should be finished'',
	    ''finished'',
	    v_state
	);

	--utresult.show;

        return null;

end;' language 'plpgsql';

SELECT setup ();
SELECT run ();

drop function setup();
drop function run();
drop function teardown();
drop function utassert__eq(varchar,integer,integer);
drop function utassert__eq(varchar,text,text);
