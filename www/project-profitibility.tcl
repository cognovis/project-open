# /packages/intranet-reporting/www/projects-timesheet.tcl
#
# Copyright (C) 2003-2012 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.
# author: Klaus Hofeditz klaus.hofeditz@project-open.com 
# author: Frank Bergmann frank.bergmann@project-open.com  

ad_page_contract {

} {
    { start_date "" }
    { end_date "" }
    { output_format "html" }
    { project_id:integer 0 }
    { project_status_id_from_search:integer 0 }
    { customer_id:integer 0 }
    { user_id_from_search:integer 0 }
    { opened_projects:multiple "" }
    { written_order_form_p:integer 0 }
    { csv_export "" }
}


set params [list \
		[list start_date $start_date] \
		[list end_date $end_date] \
                [list output_format $output_format] \
                [list project_id $project_id] \
                [list project_status_id_from_search $project_status_id_from_search] \
                [list customer_id $customer_id] \
                [list user_id_from_search $user_id_from_search] \
		[list opened_projects $opened_projects] \
		[list written_order_form_p $written_order_form_p] \
		[list csv_export $csv_export] \
		]

set result [ad_parse_template -params $params "/packages/intranet-cust-koernigweber/lib/project-profitibility"]
ns_return 200 text/html $result
