select workflow__new('test_workflow', 'Test Workflow', '2706', 'acs_object', '3606', '122.122.122.122', '2706');
insert into workflow_actions select nextval('workflow_actions_seq'), '4212', '1', 'test_action', 'Test Action', NULL, NULL;
insert into workflow_fsm_actions select action_id, NULL from workflow_actions where short_name = 'test_action';
