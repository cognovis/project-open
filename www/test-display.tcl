set case_id 2002
set workflow_key [db_string workflow_key_from_case_id { select workflow_key from wf_cases where case_id = :case_id }]


set workflow_info [wf_get_workflow_net $workflow_key]


doc_return 200 text/html "
<html>
<head>
<title>test</title>
<body>
workflow_key : $workflow_key <p>
workflow_info :$workflow_info <p>

</body>
</html>
"