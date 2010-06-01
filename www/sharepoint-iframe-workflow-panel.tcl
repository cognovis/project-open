# /packages/intranet-cust-dhl-mcc/www/sharepoint-iframe.tcl
#
# Copyright (C) 2010 ]project-open[ for DHL
#
# All rights reserved.


# Workflow-Panel
# This code is called when this page is embedded in a WF "Panel"
# Calculate an iFrame URL based on project information

# Get the information about the ACS-Workflow "Task":
if {![info exists task]} { 
    ad_return_complaint 1 "There is not 'task': Please call this page from a Workflow"
}
set task_id $task(task_id)
set case_id $task(case_id)


# Return-URL Logic
set return_url ""
if {[info exists task(return_url)]} { set return_url $task(return_url) }


# The wf_cases table contains a field "object_id" which points
# to the object underlying the workflow
set project_id [db_string pid "select object_id from wf_cases where case_id = :case_id" -default ""]
if {"" == $project_id} { 
    ad_return_complaint 1 "Didn't find project_id for case \#$case_id"
}

# Pull out all information about the project and it's customer
# and store them (automagically) into local variables.
db_1row project_info "
	select	*
	from	im_projects p,
		im_companies c
	where
		project_id = :project_id and
		c.company_id = p.company_id
"


# Variables "project_path" and "company_path" are now defined



# The Sharepoint URL may contain TCL variables and expressions
set url_tcl [parameter::get_from_package_key -package_key "intranet-sharepoint" -parameter SharepointUrl -default "http://www.microsoft.com.com/"]
eval "set url $url_tcl"

