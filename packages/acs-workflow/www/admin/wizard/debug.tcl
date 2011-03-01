set tasks_client_property [ad_get_client_property wf tasks]

doc_body_append "<pre>"

foreach entry $tasks_client_property {
    foreach { key value } $entry {
	doc_body_append "$key=$value\n"
    }
    doc_body_append "\n----\n\n"
}

doc_body_append "</pre>"