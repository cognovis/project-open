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


db_1row get_cnt "
        select
		count(*) as inquiries_count
        from
        (
                select
                        inquiry_id,
                        title,
                        inquiry_date,
                        status_id,
                        project_id
                from
                        im_inquiries_customer_portal
        ) as i
        left outer join
                im_costs
        on
                i.project_id = im_costs.project_id
"


set row_count 0

db_multirow -extend { id action_column} inquiries inquiries_query {
        select
                i.inquiry_id,
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
		i.project_id
        from
        (
                select
                        inquiry_id,
                        title,
                        inquiry_date,
                        status_id,
                        project_id,
			company_id,
			company_name
                from
                        im_inquiries_customer_portal
        ) as i

        left outer join
                im_costs
        on
                i.project_id = im_costs.project_id
} {
	set action_column ""
	set id [expr $row_count + 1 ]
	if { ""==$cost_name } { 
		set cost_name "inquiring" 
	} else {
                set cost_name "<a href='/intranet-invoices/view?invoice_id=$cost_id'>$cost_name</a>"	
	        set action_column "<img id='buttonAcceptQuote' src='/resources/themes/images/default/dd/drop-yes.gif'>&nbsp;<img id='buttonRejectQuote' src='/resources/themes/images/default/grid/drop-no.gif'>"}

	incr row_count

# <a href='/intranet-invoices/view?invoice_id=$cost_id'><img src='/resources/themes/images/default/dd/drop-yes.gif'></a>
# <a href='/intranet-invoices/view?invoice_id=$cost_id'><img src='/resources/themes/images/default/grid/drop-no.gif'></a>-->

}

