# /packages/intranet-customer-portal/www/wizard/index.tcl
#
# Copyright (C) 2011 ]project-open[
# The code is based on ArsDigita ACS 3.4
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

ad_page_contract {
    @param
    @author Klaus Hofeditz (klaus.hofeditz@project-open.com)
} { }


# ---------------------------------------------------------------
# Returns inquiries as JSON 
# ---------------------------------------------------------------

# todo: improve 
set user_id [ad_maybe_redirect_for_registration]

set where_clause ""
if { ![im_profile::member_p -profile_id [im_employee_group_id] -user_id $user_id] } {
	set where_clause "and user_id = :user_id"
}

set inquiries_query "
        select
                i.inquiry_id,
		i.user_id,
                i.title,
                i.inquiry_date,
                i.status_id,
                CASE i.company_id <> 0
	                WHEN true THEN
	                        (select company_name from im_companies where company_id = i.company_id)
			ELSE
				company_name
                END as company_name,
                im_costs.cost_name,
                trunc((im_costs.amount ) :: numeric, 2) as amount,
                im_costs.currency,
                im_costs.cost_id, 
    		im_costs.template_id,
		i.project_id
        from
        (
                select
                        inquiry_id,
			user_id,
                        title,
                        inquiry_date,
                        status_id,
                        project_id,
			company_id,
			company_name
                from
                        im_inquiries_customer_portal
                where
                        status_id <> 380 
			and status_id <> 77
			$where_clause 		
        ) as i

        left outer join
                im_costs
        on
                i.project_id = im_costs.project_id and	 
		im_costs.cost_status_id = 3802
"

set row_count 0
db_multirow -extend { id action_column} inquiries inquiries_query $inquiries_query {
	set action_column ""
	set id [expr $row_count + 1 ]
    	set status_id [im_category_from_id $status_id]

        if { ""==$amount } { set amount "---" }
        if { ""==$currency } { set currency "---" }

	if { ""==$cost_name } { 
		set cost_name "---" 
	} else {
		# Make sure that user who inquired gets read permissions 
		permission::grant -object_id $cost_id -party_id $user_id -privilege "read"
                set cost_name "<a href='/intranet-invoices/view?invoice_id=$cost_id&render_template_id=$template_id'>$cost_name</a>"
	        set action_column "<img id='buttonAcceptQuote' src='/resources/themes/images/default/dd/drop-yes.gif'>&nbsp;<img id='buttonRejectQuote' src='/resources/themes/images/default/grid/drop-no.gif'>"}

	incr row_count
}

set inquiries_count $row_count