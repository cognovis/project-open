
ns_cache create workflow_info -timeout 60



# Initialize a "semaphore" to 0 to protect the "dot" GraphWiz.
nsv_set acs_workflow dot_busy_p 0
