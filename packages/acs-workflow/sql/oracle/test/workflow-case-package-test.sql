set serveroutput on size 1000000 format wrapped

-- requires the utPLSQL system
-- 
-- modify this line to suit your needs
-- 
-- exec utplsql.setdir('/web/lars-dev2/packages/acs-kernel/sql');

exec utplsql.autocompile (false);

create or replace package ut#workflow_case
as

    procedure setup;

    procedure teardown;

    procedure run;

end ut#workflow_case;
/
show errors

create or replace package body ut#workflow_case
as

    procedure setup
    is
	wf_count number;
    begin
	teardown;
        dbms_output.put_line('Setting up...');

	/* We assume that the sample-expenses workflow is loaded and unchanged from the original */
	select decode(count(*),0,0,1) into wf_count from wf_workflows where workflow_key = 'expenses_wf';
	if wf_count = 0 then
	    raise_application_error(-20000, 'The sample-expenses workflow must be loaded (and unchanged from the original)');
	end if;
	
	

        utplsql.setpkg('workflow_case');
	utplsql.addtest('run');
    end;

    procedure teardown
    is
    begin
        dbms_output.put_line('Tearing down...');
	
    end;

    procedure run
    is
	v_workflow_key wf_workflows.workflow_key%TYPE;
	v_object_id acs_objects.object_id%TYPE;
	v_case_id wf_cases.case_id%TYPE;
	v_count number;
	v_task_id number;
	v_journal_id number;
	v_user_id number;
	v_state varchar2(100);
    begin
	v_workflow_key := 'expenses_wf';
	
        dbms_output.put_line('Running test...');

	/* Pick out a random object ... we just hope there is one somewhere */
	select object_id into v_object_id from acs_objects where rownum = 1;
	
        dbms_output.put_line('. new case');

	v_case_id := workflow_case.new(
            workflow_key => v_workflow_key,
            context_key => 'default',
            object_id => v_object_id
        );
	
	dbms_output.put_line('. manual assignments');

	/* we need a random user_id */
	select user_id into v_user_id
	from   users
	where  rownum = 1;

	workflow_case.add_manual_assignment (
	    case_id => v_case_id,
	    transition_key => 'assign',
	    party_id => v_user_id
	);

	workflow_case.add_manual_assignment (
	    case_id => v_case_id,
	    transition_key => 'supervisor_approval',
	    party_id => v_user_id
	);

	workflow_case.add_manual_assignment (
	    case_id => v_case_id,
	    transition_key => 'other_approval',
	    party_id => v_user_id
	);

	workflow_case.add_manual_assignment (
	    case_id => v_case_id,
	    transition_key => 'buy',
	    party_id => v_user_id
	);



	dbms_output.put_line('. start case');

	workflow_case.start_case(
	    case_id => v_case_id
        );
	
	select count(*) into v_count 
	from   wf_tasks 
	where  case_id = v_case_id
	and    transition_key = 'assign'
	and    state = 'enabled';

	utassert.eq(
	    msg_in => 'We should have exactly one ''assign'' task enabled',
	    check_this_in => 1, 
            against_this_in => v_count
        );

	select count(*) into v_count 
	from   wf_tasks 
	where  case_id = v_case_id;

	utassert.eq(
	    msg_in => 'The ''assign'' task should be the only task there is for this case yet.',
	    check_this_in => 1,
	    against_this_in => v_count
        );

	/* Get that task_id */
	select task_id into v_task_id
	from wf_tasks
	where case_id = v_case_id
	and   transition_key = 'assign'
	and   state = 'enabled';




	dbms_output.put_line('. start task ''assign''');

	v_journal_id := workflow_case.begin_task_action(
	    task_id => v_task_id,
	    action => 'start',
	    action_ip => '0.0.0.0',
	    user_id => v_user_id,
	    msg => 'regression-test: started task ''assign'''
	);

	workflow_case.end_task_action(
	    journal_id => v_journal_id,
	    action => 'start',
	    task_id => v_task_id
        );

	select state into v_state
	from   wf_tasks
	where  task_id = v_task_id;
	
	utassert.eq(
	    msg_in => 'The ''assign'' task should be in state ''started''.',
	    check_this_in => 'started',
	    against_this_in => v_state
        );




	dbms_output.put_line('. cancel task ''assign''');

	v_journal_id := workflow_case.begin_task_action(
	    task_id => v_task_id,
	    action => 'cancel',
	    action_ip => '0.0.0.0',
	    user_id => v_user_id,
	    msg => 'regression-test: canceled task ''assign'''
	);

	workflow_case.end_task_action(
	    journal_id => v_journal_id,
	    action => 'cancel',
	    task_id => v_task_id
        );

	select state into v_state
	from   wf_tasks
	where  task_id = v_task_id;
	
	utassert.eq(
	    msg_in => 'The ''assign'' task should be in state ''canceled''.',
	    check_this_in => 'canceled',
	    against_this_in => v_state
        );

	select count(*) into v_count 
	from   wf_tasks 
	where  case_id = v_case_id
	and    transition_key = 'assign'
	and    state = 'enabled';

	utassert.eq(
	    msg_in => 'We should have exactly one ''assign'' task enabled',
	    check_this_in => 1,
            against_this_in => v_count
        );

	select count(*) into v_count 
	from   wf_tasks 
	where  case_id = v_case_id;

	utassert.eq(
	    msg_in => 'There should be exactly two tasks for this case, one enabled and one canceled.',
	    check_this_in => 2,
	    against_this_in => v_count
        );




	dbms_output.put_line('. finish task ''assign''');

	/* Get that task_id for the 'assign' task */
	select task_id into v_task_id
	from wf_tasks
	where case_id = v_case_id
	and   transition_key = 'assign'
	and   state = 'enabled';
	
	v_journal_id := workflow_case.begin_task_action(
	    task_id => v_task_id,
	    action => 'finish',
	    action_ip => '0.0.0.0',
	    user_id => v_user_id,
	    msg => 'regression-test: finished task ''assign'''
	);

	workflow_case.end_task_action(
	    journal_id => v_journal_id,
	    action => 'finish',
	    task_id => v_task_id
        );
	
	select state into v_state
	from   wf_tasks
	where  task_id = v_task_id;

	utassert.eq(
	    msg_in => 'The ''assign'' task should be in state ''finished''.',
	    check_this_in => 'finished',
	    against_this_in => v_state
        );

	select count(*) into v_count 
	from   wf_tasks 
	where  case_id = v_case_id
	and    transition_key = 'supervisor_approval'
	and    state = 'enabled';

	utassert.eq(
	    msg_in => 'We should have exactly one ''supervisor_approval'' task enabled',
	    check_this_in => 1,
            against_this_in => v_count
        );

	select count(*) into v_count 
	from   wf_tasks 
	where  case_id = v_case_id
	and    transition_key = 'other_approval'
	and    state = 'enabled';

	utassert.eq(
	    msg_in => 'We should have exactly one ''other_approval'' task enabled',
	    check_this_in => 1,
            against_this_in => v_count
        );

	select count(*) into v_count 
	from   wf_tasks 
	where  case_id = v_case_id;

	utassert.eq(
	    msg_in => 'There should be exactly five tasks for this case, one canceled, two finished, and two enabled.',
	    check_this_in => 5,
	    against_this_in => v_count
        );

	
	dbms_output.put_line('. finish task ''supervisor_approval'' without starting it first (saying okay)');

	/* Get the task_id for the supervisor_approval task */
	select task_id into v_task_id
	from wf_tasks
	where case_id = v_case_id
	and   transition_key = 'supervisor_approval'
	and   state = 'enabled';

	v_journal_id := workflow_case.begin_task_action(
	    task_id => v_task_id,
	    action => 'finish',
	    action_ip => '0.0.0.0',
	    user_id => v_user_id,
	    msg => 'regression-test: finished task ''supervisor_approval'''
	);

	workflow_case.set_attribute_value(
	    journal_id => v_journal_id,
	    attribute_name => 'supervisor_ok',
	    value => 't'
        );

	workflow_case.end_task_action(
	    journal_id => v_journal_id,
	    action => 'finish',
	    task_id => v_task_id
        );
	
	select state into v_state
	from   wf_tasks
	where  task_id = v_task_id;

	utassert.eq(
	    msg_in => 'The ''supervisor_approval'' task should be in state ''finished''.',
	    check_this_in => 'finished',
	    against_this_in => v_state
        );
	


	dbms_output.put_line('. finish task ''other_approval'' without starting it first (saying okay)');

	/* Get the task_id for the other_approval task */
	select task_id into v_task_id
	from wf_tasks
	where case_id = v_case_id
	and   transition_key = 'other_approval'
	and   state = 'enabled';

	v_journal_id := workflow_case.begin_task_action(
	    task_id => v_task_id,
	    action => 'finish',
	    action_ip => '0.0.0.0',
	    user_id => v_user_id,
	    msg => 'regression-test: finished task ''other_approval'''
	);

	workflow_case.set_attribute_value(
	    journal_id => v_journal_id,
	    attribute_name => 'other_ok',
	    value => 't'
        );

	workflow_case.end_task_action(
	    journal_id => v_journal_id,
	    action => 'finish',
	    task_id => v_task_id
        );
	
	select state into v_state
	from   wf_tasks
	where  task_id = v_task_id;

	utassert.eq(
	    msg_in => 'The ''other_approval'' task should be in state ''finished''.',
	    check_this_in => 'finished',
	    against_this_in => v_state
        );
	
	select count(*) into v_count 
	from   wf_tasks 
	where  case_id = v_case_id
	and    state = 'enabled';

	utassert.eq(
	    msg_in => 'We should have exactly one task enabled',
	    check_this_in => 1,
            against_this_in => v_count
        );

	select count(*) into v_count 
	from   wf_tasks 
	where  case_id = v_case_id
	and    transition_key = 'buy'
	and    state = 'enabled';

	utassert.eq(
	    msg_in => 'We should have the ''buy'' task enabled',
	    check_this_in => 1,
            against_this_in => v_count
        );

	select count(*) into v_count 
	from   wf_tasks 
	where  case_id = v_case_id;

	utassert.eq(
	    msg_in => 'There should be exactly seven tasks for this case, one canceled, six finished, and one enabled.',
	    check_this_in => 7,
	    against_this_in => v_count
        );

	select count(*) into v_count 
	from   wf_tasks 
	where  case_id = v_case_id
	and    state = 'finished';

	utassert.eq(
	    msg_in => 'There should be exactly five finished tasks',
	    check_this_in => 5,
	    against_this_in => v_count
        );

	select count(*) into v_count 
	from   wf_tasks 
	where  case_id = v_case_id
	and    state = 'canceled';

	utassert.eq(
	    msg_in => 'There should be exactly one canceled task',
	    check_this_in => 1,
	    against_this_in => v_count
        );
	

	dbms_output.put_line('. finish task ''buy''');

	/* Get that task_id for the 'buy' task */
	select task_id into v_task_id
	from wf_tasks
	where case_id = v_case_id
	and   transition_key = 'buy'
	and   state = 'enabled';
	
	v_journal_id := workflow_case.begin_task_action(
	    task_id => v_task_id,
	    action => 'finish',
	    action_ip => '0.0.0.0',
	    user_id => v_user_id,
	    msg => 'regression-test: finished task ''buy'''
	);

	workflow_case.end_task_action(
	    journal_id => v_journal_id,
	    action => 'finish',
	    task_id => v_task_id
        );
	
	select state into v_state
	from   wf_tasks
	where  task_id = v_task_id;

	utassert.eq(
	    msg_in => 'The ''buy'' task should be in state ''finished''.',
	    check_this_in => 'finished',
	    against_this_in => v_state
        );

	select count(*) into v_count 
	from   wf_tasks 
	where  case_id = v_case_id;

	utassert.eq(
	    msg_in => 'There should be exactly seven tasks for this case, one canceled, six finished, and one enabled.',
	    check_this_in => 7,
	    against_this_in => v_count
        );

	select count(*) into v_count 
	from   wf_tasks 
	where  case_id = v_case_id
	and    state = 'finished';

	utassert.eq(
	    msg_in => 'There should be exactly six finished tasks',
	    check_this_in => 6,
	    against_this_in => v_count
        );

	select count(*) into v_count 
	from   wf_tasks 
	where  case_id = v_case_id
	and    state = 'canceled';

	utassert.eq(
	    msg_in => 'There should be exactly one canceled task',
	    check_this_in => 1,
	    against_this_in => v_count
        );
	
	select state into v_state
	from   wf_cases
	where  case_id = v_case_id;

	utassert.eq(
	    msg_in => 'The case should be finished',
	    check_this_in => 'finished',
	    against_this_in => v_state
	);

	utresult.show;
    end;

end ut#workflow_case;
/
show errors

exec utplsql.test('workflow_case');