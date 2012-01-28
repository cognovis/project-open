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
} {
    {inquiry_id ""}
}


# ---------------------------------------------------------------
# Returns inquiries as JSON 
# ---------------------------------------------------------------


db_1row get_cnt "select count(*) as inquiries_count from im_inquiries_customer_portal"

set row_count 0


db_multirow -extend { prospect_project_type } inquiries inquiries_query {
        select
                inquiry_id, 
    		(first_names || ' ' || last_names) as name, 
		email, 
		company_name,
		phone
        from
                im_inquiries_customer_portal
} {
	incr row_count
	set email "\"$email\""
    	if { ""==$company_name } {
		set company_name "\"not defined\""
    	}
}

