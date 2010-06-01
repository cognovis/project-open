# -------------------------------------------------------------
# /packages/intranet-cust-dhl-mcc/www/portlet/sharepoint-iframe-component.tcl
#
# Copyright (c) 2010 ]project-open[ for DHL
# All rights reserved.
#
# Author: frank.bergmann@project-open.com
#

# -------------------------------------------------------------
# Variables:
#	project_id:integer
#	return_url

if {![info exists project_id]} {

    # Header for showing this page outside of the Workflow
    # That's handy for debugging etc.
    ad_page_contract {
	@author frank.bergmann@project-open.com
    } {
	{ project_id "" }
    }

}

# Check for reasonable input
if {![info exists project_id] || "" == $project_id} { 
    ad_return_complaint 1 "Didn't find project_id"
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

set base_url "http://ishare.company.com/base-folder"
set url "$base_url/$company_path/$project_path/"

