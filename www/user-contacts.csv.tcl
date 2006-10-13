# /packages/intranet-reporting-tutorial/www/projects-01.csv.tcl
#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved. 
# Please see http://www.project-open.com/ for licensing.

ad_page_contract {
    Shows a list of all users in the system, together with
    their contact information,
} {
    { level_of_detail:integer 3 }
    { company_id 0 }
    { output_format "html" }
    { encoding "" }
}

# rp_form_put level_of_detail $level_of_detail
# rp_form_put company_id $company_id
# rp_form_put output_format $output_format
# rp_form_put encoding $encoding

# Avoid that the reports redirects to this page again
rp_form_put redirect_p 0

rp_internal_redirect user-contacts
