# /packages/intranet-freelance-rfqs/www/invite-rfq-members
#
# Copyright (c) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.


ad_page_contract {
    Purpose: Process one or more users to a RFQ

    @param user_id user_id to add
    @param rfq_id RFQ to which to add 
    @param return_url Return URL

    @author frank.bergmann@project-open.com
} {
    { user_ids:integer,multiple "" }
    { notify_asignee 1 }
    rfq_id:integer
    return_url
}

ad_returnredirect [export_vars -base "process-rfq-members" {{rfq_action invite} user_ids notify_assignee rfq_id return_url}]

